drop policy if exists digital_orders_own on public.digital_orders;

create policy digital_orders_customer_read
on public.digital_orders
for select
to authenticated
using (customer_id = auth.uid());
