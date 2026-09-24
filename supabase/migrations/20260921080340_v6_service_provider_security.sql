
create policy service_provider_own_read on public.service_providers
for select to authenticated
using(user_id=(select auth.uid()) or (active=true and verification_status='VERIFIED'));

create policy services_provider_manage on public.services
for all to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())))
with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

create policy availability_provider_manage on public.availability_schedules
for all to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())))
with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

create policy timeoff_provider_manage on public.provider_time_off
for all to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())))
with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

create policy provider_locations_provider_read on public.provider_locations
for select to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));
