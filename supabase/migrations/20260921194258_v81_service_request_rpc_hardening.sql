create or replace function public.create_service_request(
  p_service_id uuid,
  p_scheduled_at timestamptz default null,
  p_latitude double precision default null,
  p_longitude double precision default null,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_request uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_service_id is null then raise exception 'service_required'; end if;

  if not exists (
    select 1
    from public.services sv
    join public.service_providers sp on sp.id = sv.provider_id
    where sv.id = p_service_id
      and sv.active = true
      and sp.active = true
  ) then
    raise exception 'service_unavailable';
  end if;

  if (p_latitude is not null and (p_latitude < -90 or p_latitude > 90))
     or (p_longitude is not null and (p_longitude < -180 or p_longitude > 180)) then
    raise exception 'invalid_coordinates';
  end if;

  insert into public.service_requests(
    service_id, customer_id, status, scheduled_at,
    latitude, longitude, description
  )
  values(
    p_service_id, v_user, 'PENDING', p_scheduled_at,
    p_latitude, p_longitude, nullif(trim(p_description), '')
  )
  returning id into v_request;

  return v_request;
end;
$function$;

revoke all on function public.create_service_request(uuid,timestamptz,double precision,double precision,text)
  from public, anon;
grant execute on function public.create_service_request(uuid,timestamptz,double precision,double precision,text)
  to authenticated;
