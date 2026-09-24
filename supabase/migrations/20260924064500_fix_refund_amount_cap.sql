create or replace function public.request_refund(
  p_order_id uuid,
  p_amount numeric,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_user uuid := auth.uid();
  v_refund uuid;
  v_payment public.payments%rowtype;
  v_refunded numeric := 0;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'invalid_refund_amount';
  end if;

  if not exists (
    select 1
    from public.orders
    where id = p_order_id
      and customer_id = v_user
  ) and not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  select p.*
    into v_payment
  from public.payments p
  where p.order_id = p_order_id
    and p.status in ('SUCCEEDED','PARTIALLY_REFUNDED')
  order by p.created_at asc, p.id asc
  limit 1
  for update;

  if not found then
    raise exception 'no_successful_payment';
  end if;

  select coalesce(sum(r.amount), 0)
    into v_refunded
  from public.refunds r
  where r.payment_id = v_payment.id
    and r.status not in ('REJECTED','CANCELLED');

  if v_refunded + p_amount > v_payment.amount then
    raise exception 'refund_amount_exceeds_payment';
  end if;

  insert into public.refunds(
    payment_id,
    order_id,
    amount,
    currency,
    reason,
    status
  )
  values(
    v_payment.id,
    p_order_id,
    p_amount,
    'XOF',
    p_reason,
    'REQUESTED'
  )
  returning id into v_refund;

  if v_refund is null then
    raise exception 'refund_payment_not_found';
  end if;

  return v_refund;
end;
$function$;
