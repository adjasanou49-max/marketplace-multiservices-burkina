
create or replace function public.get_parcel_tracking(
  p_tracking_code text
)
returns jsonb
language plpgsql
security definer
stable
set search_path = pg_catalog, public
as $$
declare
  v_code text := upper(trim(coalesce(p_tracking_code,'')));
  v_parcel record;
  v_events jsonb;
begin
  if (select auth.uid()) is null then
    raise exception 'not_authenticated';
  end if;

  if length(v_code) < 8 or length(v_code) > 64 then
    raise exception 'tracking_code_invalid';
  end if;

  select p.id,p.tracking_code,p.status,p.created_at
    into v_parcel
  from public.parcels p
  where upper(p.tracking_code)=v_code
  limit 1;

  if not found then
    raise exception 'parcel_not_found';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'status',e.status,
        'latitude',e.latitude,
        'longitude',e.longitude,
        'created_at',e.created_at
      )
      order by e.created_at
    ),
    '[]'::jsonb
  )
  into v_events
  from public.parcel_events e
  where e.parcel_id=v_parcel.id;

  return jsonb_build_object(
    'tracking_code',v_parcel.tracking_code,
    'status',v_parcel.status,
    'created_at',v_parcel.created_at,
    'events',v_events
  );
end;
$$;

revoke all on function public.get_parcel_tracking(text) from public,anon;
grant execute on function public.get_parcel_tracking(text) to authenticated;
