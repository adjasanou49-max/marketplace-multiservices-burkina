
create or replace function public.cancel_unpaid_order(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_user uuid := (select auth.uid());
  v_order public.orders%rowtype;
  v_item record;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;

  select * into v_order from public.orders
  where id=p_order_id and customer_id=v_user
  for update;
  if not found then raise exception 'order_not_found'; end if;
  if v_order.status <> 'PENDING_PAYMENT' then raise exception 'order_not_cancellable'; end if;

  for v_item in
    select oi.product_id, sum(oi.quantity)::integer as qty
    from public.order_items oi
    join public.order_groups og on og.id=oi.order_group_id
    where og.order_id=p_order_id
    group by oi.product_id
  loop
    perform public.release_inventory(v_item.product_id,v_item.qty);
  end loop;

  update public.order_packages op
  set status='CANCELLED', updated_at=now()
  from public.order_groups og
  where og.id=op.order_group_id and og.order_id=p_order_id;

  update public.order_groups
  set status='CANCELLED'
  where order_id=p_order_id;

  update public.orders
  set status='CANCELLED', updated_at=now()
  where id=p_order_id;

  return true;
end
$$;
revoke execute on function public.cancel_unpaid_order(uuid) from public,anon,authenticated;

create or replace function public.transition_order_group(
  p_order_group_id uuid,
  p_status public.order_status
) returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_user uuid := (select auth.uid());
  v_current public.order_status;
  v_shop_owner uuid;
  v_order_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;

  select og.status, og.order_id, s.seller_id into v_current,v_order_id,v_shop_owner
  from public.order_groups og
  join public.shops s on s.id=og.shop_id
  where og.id=p_order_group_id
  for update;

  if not found then raise exception 'order_group_not_found'; end if;

  if v_shop_owner <> (select id from public.sellers where user_id=v_user)
     and not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  if p_status='CONFIRMED' and v_current <> 'PAID' then raise exception 'invalid_transition'; end if;
  if p_status='PREPARING' and v_current <> 'CONFIRMED' then raise exception 'invalid_transition'; end if;
  if p_status='READY_FOR_PICKUP' and v_current <> 'PREPARING' then raise exception 'invalid_transition'; end if;

  if public.is_admin() then
    update public.order_groups set status=p_status where id=p_order_group_id;
  else
    update public.order_groups set status=p_status where id=p_order_group_id;
  end if;

  return true;
end
$$;
revoke execute on function public.transition_order_group(uuid,public.order_status) from public,anon,authenticated;
