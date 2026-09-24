
create unique index if not exists uq_payment_events_provider_ref
on public.payment_events(provider_reference)
where provider_reference is not null;

create unique index if not exists uq_payments_order_pending
on public.payments(order_id)
where status in ('PENDING','PROCESSING');

create or replace function public.create_payment_intent(
  p_order_id uuid,
  p_provider text
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_user uuid := (select auth.uid());
  v_payment uuid;
  v_amount numeric;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_provider is null or length(trim(p_provider))=0 then raise exception 'provider_required'; end if;

  select total into v_amount
  from public.orders
  where id=p_order_id and customer_id=v_user
  for update;
  if not found then raise exception 'order_not_owned'; end if;
  if v_amount <= 0 then raise exception 'invalid_payment_amount'; end if;

  select id into v_payment
  from public.payments
  where order_id=p_order_id and status in ('PENDING','PROCESSING')
  order by created_at desc
  limit 1;

  if v_payment is not null then return v_payment; end if;

  insert into public.payments(order_id,provider,amount,currency,status,metadata)
  values(p_order_id,trim(p_provider),v_amount,'XOF','PENDING','{}'::jsonb)
  returning id into v_payment;

  return v_payment;
end;
$$;
revoke all on function public.create_payment_intent(uuid,text) from public,anon,authenticated;
grant execute on function public.create_payment_intent(uuid,text) to service_role;

create or replace function public.process_payment_event(
  p_payment_id uuid,
  p_event_type text,
  p_status public.payment_status,
  p_provider_reference text,
  p_amount numeric,
  p_payload jsonb default '{}'::jsonb
) returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_payment public.payments%rowtype;
  v_order public.orders%rowtype;
  v_item record;
begin
  if p_payment_id is null or p_event_type is null or length(trim(p_event_type))=0 then
    raise exception 'payment_event_invalid';
  end if;
  if p_amount <= 0 then raise exception 'payment_amount_invalid'; end if;

  select * into v_payment from public.payments where id=p_payment_id for update;
  if not found then raise exception 'payment_not_found'; end if;

  if v_payment.amount <> p_amount or v_payment.currency <> 'XOF' then
    raise exception 'payment_amount_mismatch';
  end if;

  if p_provider_reference is not null and exists (
    select 1 from public.payment_events
    where provider_reference=p_provider_reference
      and payment_id=p_payment_id
  ) then
    return true;
  end if;

  insert into public.payment_events(payment_id,event_type,provider_reference,payload)
  values(p_payment_id,trim(p_event_type),p_provider_reference,coalesce(p_payload,'{}'::jsonb));

  update public.payments
  set status=p_status,
      provider_reference=coalesce(p_provider_reference,provider_reference),
      metadata=coalesce(metadata,'{}'::jsonb) || coalesce(p_payload,'{}'::jsonb),
      updated_at=now()
  where id=p_payment_id;

  select * into v_order from public.orders where id=v_payment.order_id for update;
  if not found then raise exception 'order_not_found'; end if;

  if p_status = 'SUCCEEDED' then
    if v_order.status = 'PENDING_PAYMENT' then
      update public.orders set status='PAID', updated_at=now() where id=v_order.id;
      update public.order_groups set status='PAID' where order_id=v_order.id and status='PENDING_PAYMENT';
      insert into public.order_events(order_id,actor_id,status,metadata)
      values(v_order.id,null,'PAID',jsonb_build_object('payment_id',p_payment_id,'provider_reference',p_provider_reference));
    end if;
  elsif p_status in ('FAILED','CANCELLED') then
    if v_order.status = 'PENDING_PAYMENT' then
      for v_item in
        select oi.product_id, oi.quantity
        from public.order_items oi
        join public.order_groups og on og.id=oi.order_group_id
        where og.order_id=v_order.id
      loop
        perform public.release_inventory(v_item.product_id,v_item.quantity);
      end loop;

      delete from public.coupon_usage where order_id=v_order.id;
      update public.coupons c
      set used_count=greatest(0,used_count-1)
      where exists (
        select 1 from public.coupon_usage cu
        where cu.coupon_id=c.id and cu.order_id=v_order.id
      );

      update public.orders set status='CANCELLED', updated_at=now() where id=v_order.id;
      update public.order_groups set status='CANCELLED' where order_id=v_order.id and status='PENDING_PAYMENT';
      insert into public.order_events(order_id,actor_id,status,metadata)
      values(v_order.id,null,'CANCELLED',jsonb_build_object('payment_id',p_payment_id,'reason','payment_failed'));
    end if;
  end if;

  return true;
end;
$$;
revoke all on function public.process_payment_event(uuid,text,public.payment_status,text,numeric,jsonb) from public,anon,authenticated;
grant execute on function public.process_payment_event(uuid,text,public.payment_status,text,numeric,jsonb) to service_role;
