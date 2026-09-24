
drop policy if exists mechanic_request_own on public.mechanic_requests;
create policy mechanic_request_customer_read
on public.mechanic_requests
for select
to authenticated
using (customer_id = (select auth.uid()));

drop policy if exists transport_booking_own on public.transport_bookings;
create policy transport_booking_customer_read
on public.transport_bookings
for select
to authenticated
using (customer_id = (select auth.uid()));
