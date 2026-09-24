begin;

drop policy if exists mechanics_public on public.mechanics;
create policy mechanics_public
on public.mechanics
for select
to anon, authenticated
using (active = true and verification_status = 'VERIFIED');

revoke select on table public.mechanics from anon, authenticated;
grant select (
  id,
  display_name,
  verification_status,
  active,
  service_radius_km
) on table public.mechanics to anon, authenticated;

commit;