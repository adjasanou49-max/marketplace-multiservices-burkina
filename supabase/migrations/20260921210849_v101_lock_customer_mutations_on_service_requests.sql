
drop policy if exists service_requests_customer on public.service_requests;

create policy service_requests_customer_read
on public.service_requests
for select
to authenticated
using (customer_id = (select auth.uid()));
