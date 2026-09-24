drop policy if exists accommodation_bookings_own on public.accommodation_bookings;

create policy accommodation_bookings_customer_read
on public.accommodation_bookings
for select
to authenticated
using (customer_id = auth.uid());
