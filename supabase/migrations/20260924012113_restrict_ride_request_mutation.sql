drop policy if exists ride_requests_own on public.ride_requests;

create policy ride_requests_customer_read
on public.ride_requests
for select
to authenticated
using (customer_id = auth.uid());
