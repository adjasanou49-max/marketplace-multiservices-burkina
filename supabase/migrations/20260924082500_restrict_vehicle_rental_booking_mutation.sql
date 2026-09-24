drop policy if exists vehicle_rental_bookings_own on public.vehicle_rental_bookings;

create policy vehicle_rental_bookings_customer_read
on public.vehicle_rental_bookings
for select
to authenticated
using (customer_id = auth.uid());
