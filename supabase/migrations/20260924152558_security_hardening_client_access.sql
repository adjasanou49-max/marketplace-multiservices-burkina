begin;

revoke all on table public.spatial_ref_sys from public, anon, authenticated;

revoke all on function public.st_estimatedextent(text, text)
  from public, anon, authenticated;
revoke all on function public.st_estimatedextent(text, text, text)
  from public, anon, authenticated;
revoke all on function public.st_estimatedextent(text, text, text, boolean)
  from public, anon, authenticated;

create or replace function public.get_public_mechanics()
returns table(
  id uuid,
  display_name text,
  service_radius_km numeric,
  availability_status text,
  availability_starts_at timestamptz,
  availability_ends_at timestamptz,
  services jsonb
)
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
begin
  if (select auth.uid()) is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  return query
  select
    m.id,
    m.display_name,
    m.service_radius_km,
    coalesce(a.status, 'UNAVAILABLE') as availability_status,
    a.starts_at as availability_starts_at,
    a.ends_at as availability_ends_at,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'service_type', ms.service_type,
            'vehicle_type', ms.vehicle_type,
            'base_price', ms.base_price
          )
          order by ms.service_type
        )
        from public.mechanic_services ms
        where ms.mechanic_id = m.id
          and ms.active = true
      ),
      '[]'::jsonb
    ) as services
  from public.mechanics m
  left join lateral (
    select ma.status, ma.starts_at, ma.ends_at
    from public.mechanic_availability ma
    where ma.mechanic_id = m.id
      and ma.starts_at <= now()
      and (ma.ends_at is null or ma.ends_at > now())
    order by ma.starts_at desc, ma.id desc
    limit 1
  ) a on true
  where m.active = true
    and m.verification_status = 'VERIFIED'
    and not exists (
      select 1
      from public.mechanic_time_off tof
      where tof.mechanic_id = m.id
        and tof.starts_at <= now()
        and tof.ends_at > now()
    )
  order by m.display_name
  limit 100;
end;
$function$;

revoke all on function public.get_public_mechanics()
  from public, anon, authenticated;
grant execute on function public.get_public_mechanics()
  to authenticated, service_role;

commit;
