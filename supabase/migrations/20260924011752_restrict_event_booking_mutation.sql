drop policy if exists event_bookings_own on public.event_bookings;

create policy event_bookings_customer_read
on public.event_bookings
for select
to authenticated
using (customer_id = auth.uid());

create policy event_bookings_customer_cancel_reserved
on public.event_bookings
for delete
to authenticated
using (
  customer_id = auth.uid()
  and status = 'RESERVED'
);
