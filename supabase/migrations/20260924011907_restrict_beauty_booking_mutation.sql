drop policy if exists beauty_bookings_own on public.beauty_bookings;

create policy beauty_bookings_customer_read
on public.beauty_bookings
for select
to authenticated
using (customer_id = auth.uid());
