create or replace function public.get_customer_payment_status(p_order_id uuid)
returns table (
  payment_id uuid,
  provider text,
  provider_reference text,
  amount numeric,
  currency text,
  status public.payment_status,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.provider,
    p.provider_reference,
    p.amount,
    p.currency,
    p.status,
    p.created_at,
    p.updated_at
  from public.payments p
  join public.orders o on o.id = p.order_id
  where p.order_id = p_order_id
    and o.customer_id = (select auth.uid())
  order by p.created_at desc
  limit 1;
$$;

revoke all on function public.get_customer_payment_status(uuid) from public;
revoke all on function public.get_customer_payment_status(uuid) from anon;
grant execute on function public.get_customer_payment_status(uuid) to authenticated;
