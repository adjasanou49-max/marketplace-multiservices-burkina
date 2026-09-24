
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
  v_coupon_id uuid;
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

      select coupon_id into v_coupon_id
      from public.coupon_usage
      where order_id=v_order.id
      limit 1;

      delete from public.coupon_usage where order_id=v_order.id;

      if v_coupon_id is not null then
        update public.coupons
        set used_count=greatest(0,used_count-1)
        where id=v_coupon_id;
      end if;

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
