drop policy if exists home_service_requests_own on public.home_service_requests;

create policy home_service_requests_customer_read
on public.home_service_requests
for select
to authenticated
using (customer_id = auth.uid());
