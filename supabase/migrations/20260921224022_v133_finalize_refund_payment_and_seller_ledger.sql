create or replace function public.complete_refund(p_refund_id uuid, p_provider_reference text)
returns boolean
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_refund public.refunds%rowtype;
  v_payment public.payments%rowtype;
  v_order public.orders%rowtype;
  v_group record;
  v_total_refunded numeric;
  v_total_subtotal numeric;
  v_allocated numeric;
  v_remaining numeric;
  v_is_first boolean := true;
begin
  select * into v_refund
  from public.refunds
  where id=p_refund_id
  for update;

  if not found then
    raise exception 'refund_not_found';
  end if;

  if v_refund.status='COMPLETED' then
    return true;
  end if;

  if p_provider_reference is null or length(trim(p_provider_reference))=0 then
    raise exception 'provider_reference_required';
  end if;

  select * into v_payment
  from public.payments
  where id=v_refund.payment_id
  for update;

  if not found then
    raise exception 'payment_not_found';
  end if;

  select * into v_order
  from public.orders
  where id=v_refund.order_id
  for update;

  if not found then
    raise exception 'order_not_found';
  end if;

  update public.refunds
  set status='COMPLETED',
      provider_reference=trim(p_provider_reference),
      completed_at=now()
  where id=p_refund_id;

  select coalesce(sum(r.amount),0)
    into v_total_refunded
  from public.refunds r
  where r.payment_id=v_refund.payment_id
    and r.status='COMPLETED';

  if v_total_refunded >= v_payment.amount then
    update public.payments
    set status='REFUNDED', updated_at=now()
    where id=v_payment.id;

    update public.orders
    set status='REFUNDED', updated_at=now()
    where id=v_order.id
      and status in ('PAID','CONFIRMED','PREPARING','READY_FOR_PICKUP','PARTIALLY_FULFILLED','IN_TRANSIT','DELIVERED','DISPUTED');

    update public.order_groups
    set status='REFUNDED'
    where order_id=v_order.id
      and status <> 'REFUNDED';
  else
    update public.payments
    set status='PARTIALLY_REFUNDED', updated_at=now()
    where id=v_payment.id
      and status='SUCCEEDED';
  end if;

  select coalesce(sum(og.subtotal),0)
    into v_total_subtotal
  from public.order_groups og
  where og.order_id=v_order.id;

  if v_total_subtotal > 0 then
    v_remaining := v_refund.amount;

    for v_group in
      select og.id as order_group_id, og.shop_id, og.subtotal
      from public.order_groups og
      where og.order_id=v_order.id
      order by og.created_at, og.id
    loop
      if v_is_first then
        v_allocated := least(
          v_remaining,
          round(v_refund.amount * v_group.subtotal / v_total_subtotal, 2)
        );
        v_is_first := false;
      else
        v_allocated := least(
          v_remaining,
          round(v_refund.amount * v_group.subtotal / v_total_subtotal, 2)
        );
      end if;

      if v_group.order_group_id = (
        select og2.id
        from public.order_groups og2
        where og2.order_id=v_order.id
        order by og2.created_at desc, og2.id desc
        limit 1
      ) then
        v_allocated := v_remaining;
      end if;

      if v_allocated > 0 then
        insert into public.seller_ledger(
          seller_id,order_group_id,entry_type,amount,currency,reference_id
        )
        select s.id,v_group.order_group_id,'REFUND',-v_allocated,'XOF',v_refund.id
        from public.shops sh
        join public.sellers s on s.id=sh.seller_id
        where sh.id=v_group.shop_id;

        v_remaining := greatest(0, v_remaining - v_allocated);
      end if;
    end loop;
  end if;

  return true;
end;
$function$;

revoke all on function public.complete_refund(uuid,text) from public;
revoke all on function public.complete_refund(uuid,text) from anon;
grant execute on function public.complete_refund(uuid,text) to service_role;
