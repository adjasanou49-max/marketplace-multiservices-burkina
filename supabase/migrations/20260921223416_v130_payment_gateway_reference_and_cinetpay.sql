
create or replace function public.create_payment_intent(p_order_id uuid, p_provider text)
returns uuid
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_payment uuid;
  v_amount numeric;
  v_provider text := upper(trim(coalesce(p_provider, '')));
  v_status text;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_order_id is null then raise exception 'order_required'; end if;

  if v_provider not in ('WAVE','ORANGE_MONEY','MOOV_MONEY','CINETPAY') then
    raise exception 'provider_invalid';
  end if;

  select total, status::text
  into v_amount, v_status
  from public.orders
  where id = p_order_id and customer_id = v_user
  for update;

  if not found then raise exception 'order_not_owned'; end if;
  if v_status <> 'PENDING_PAYMENT' then raise exception 'order_not_payable'; end if;
  if v_amount is null or v_amount <= 0 then raise exception 'invalid_payment_amount'; end if;

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
    order_id, provider, amount, currency, status, metadata
  )
  values(
    p_order_id, v_provider, v_amount, 'XOF', 'PENDING',
    jsonb_build_object('gateway', case when v_provider='CINETPAY' then 'CINETPAY' else v_provider end)
  )
  returning id into v_payment;

  return v_payment;
end;
$function$;

revoke all on function public.create_payment_intent(uuid,text) from public;
revoke all on function public.create_payment_intent(uuid,text) from anon;
grant execute on function public.create_payment_intent(uuid,text) to authenticated;

create or replace function public.prepare_payment_processing(
  p_payment_id uuid,
  p_provider_reference text,
  p_metadata jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_payment public.payments%rowtype;
  v_order public.orders%rowtype;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_payment_id is null or p_provider_reference is null
     or length(trim(p_provider_reference)) = 0 then
    raise exception 'payment_session_invalid';
  end if;

  select * into v_payment from public.payments where id=p_payment_id for update;
  if not found then raise exception 'payment_not_found'; end if;

  select * into v_order
  from public.orders
  where id=v_payment.order_id and customer_id=v_user
  for update;
  if not found then raise exception 'order_not_owned'; end if;

  if v_order.status <> 'PENDING_PAYMENT' then raise exception 'order_not_payable'; end if;
  if v_payment.status not in ('PENDING','PROCESSING') then raise exception 'payment_not_pending'; end if;
  if v_payment.provider not in ('WAVE','ORANGE_MONEY','MOOV_MONEY','CINETPAY') then
    raise exception 'provider_not_supported';
  end if;

  update public.payments
  set status='PROCESSING',
      provider_reference=coalesce(provider_reference, trim(p_provider_reference)),
      metadata=coalesce(metadata,'{}'::jsonb) || coalesce(p_metadata,'{}'::jsonb),
      updated_at=now()
  where id=p_payment_id;

  return true;
end;
$function$;

revoke all on function public.prepare_payment_processing(uuid,text,jsonb) from public;
revoke all on function public.prepare_payment_processing(uuid,text,jsonb) from anon;
grant execute on function public.prepare_payment_processing(uuid,text,jsonb) to authenticated;
