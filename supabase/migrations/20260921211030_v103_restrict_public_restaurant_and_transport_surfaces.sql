
drop policy if exists restaurant_public_profile on public.restaurant_profiles;
create policy restaurant_public_profile
on public.restaurant_profiles
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.shops s
    where s.id = restaurant_profiles.shop_id
      and s.status = 'ACTIVE'::public.shop_status
      and s.verification_status = 'VERIFIED'::public.verification_status
  )
);

drop policy if exists transport_public_stations on public.transport_stations;
create policy transport_public_stations
on public.transport_stations
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.transport_companies tc
    where tc.id = transport_stations.company_id
      and tc.active = true
      and tc.verification_status = 'VERIFIED'::public.verification_status
  )
);
