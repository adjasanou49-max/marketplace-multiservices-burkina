drop policy if exists payments_customer_read on public.payments;

create policy payments_customer_read
on public.payments
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = payments.order_id
      and o.customer_id = (select auth.uid())
  )
);
