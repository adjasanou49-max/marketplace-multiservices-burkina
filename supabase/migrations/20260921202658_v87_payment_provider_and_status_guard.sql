
create or replace function public.create_payment_intent(
  p_order_id uuid,
  p_provider text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_payment uuid;
  v_amount numeric;
  v_provider text := upper(trim(coalesce(p_provider, '')));
  v_status text;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  if p_order_id is null then
    raise exception 'order_required';
  end if;

  if v_provider not in ('ORANGE_MONEY', 'WAVE', 'MOOV_MONEY') then
    raise exception 'provider_invalid';
  end if;

  select total, status::text
  into v_amount, v_status
  from public.orders
  where id = p_order_id
    and customer_id = v_user
  for update;

  if not found then
    raise exception 'order_not_owned';
  end if;

  if v_status <> 'PENDING_PAYMENT' then
    raise exception 'order_not_payable';
  end if;

  if v_amount is null or v_amount <= 0 then
    raise exception 'invalid_payment_amount';
  end if;

  select id into v_payment
  from public.payments
  where order_id = p_order_id
    and status in ('PENDING','PROCESSING')
  order by created_at desc
  limit 1;

  if v_payment is not null then
    return v_payment;
  end if;

  insert into public.payments(
    order_id,
    provider,
    amount,
    currency,
    status,
    metadata
  )
  values(
    p_order_id,
    v_provider,
    v_amount,
    'XOF',
    'PENDING',
    '{}'::jsonb
  )
  returning id into v_payment;

  return v_payment;
end;
$function$;

revoke execute on function public.create_payment_intent(uuid, text) from anon, public;
grant execute on function public.create_payment_intent(uuid, text) to authenticated;
