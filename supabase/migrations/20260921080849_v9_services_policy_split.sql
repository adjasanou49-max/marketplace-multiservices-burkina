
drop policy if exists services_provider_manage on public.services;
drop policy if exists services_read on public.services;

create policy services_read on public.services
for select to authenticated
using(active=true or provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

create policy services_provider_insert on public.services
for insert to authenticated
with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

create policy services_provider_update on public.services
for update to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())))
with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

create policy services_provider_delete on public.services
for delete to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));
