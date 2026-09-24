
create or replace function public.transition_order_status(
  p_order_id uuid,
  p_next_status public.order_status,
  p_note text default null
) returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_user uuid := (select auth.uid());
 v_order public.orders%rowtype;
 v_allowed boolean := false;
 v_is_admin boolean := false;
 v_is_customer boolean := false;
 v_is_seller boolean := false;
 v_item record;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;

 select * into v_order from public.orders where id=p_order_id for update;
 if not found then raise exception 'order_not_found'; end if;

 v_is_customer := v_order.customer_id=v_user;
 v_is_admin := exists(select 1 from public.admin_users au where au.user_id=v_user and au.active=true);
 v_is_seller := exists(
   select 1 from public.order_groups og
   join public.shops sh on sh.id=og.shop_id
   join public.sellers s on s.id=sh.seller_id
   where og.order_id=p_order_id and s.user_id=v_user
 );

 if p_next_status='CANCELLED' then
   v_allowed := v_is_customer and v_order.status in ('PENDING_PAYMENT','PAID') or v_is_seller and v_order.status in ('PAID','CONFIRMED') or v_is_admin;
 elsif p_next_status='CONFIRMED' then
   v_allowed := v_is_seller and v_order.status='PAID' or v_is_admin;
 elsif p_next_status='PREPARING' then
   v_allowed := v_is_seller and v_order.status='CONFIRMED' or v_is_admin;
 elsif p_next_status='READY_FOR_PICKUP' then
   v_allowed := v_is_seller and v_order.status='PREPARING' or v_is_admin;
 elsif p_next_status='DISPUTED' then
   v_allowed := v_is_customer or v_is_seller or v_is_admin;
 else
   v_allowed := v_is_admin;
 end if;

 if not v_allowed then raise exception 'order_transition_not_allowed'; end if;

 if p_next_status='CANCELLED' and v_order.status in ('PENDING_PAYMENT','PAID','CONFIRMED','PREPARING') then
   for v_item in
     select oi.product_id, oi.quantity
     from public.order_items oi
     join public.order_groups og on og.id=oi.order_group_id
     where og.order_id=p_order_id
   loop
     perform public.release_inventory(v_item.product_id,v_item.quantity);
   end loop;
 end if;

 update public.orders set status=p_next_status,updated_at=now() where id=p_order_id;

 insert into public.order_events(order_id,actor_id,status,metadata)
 values(p_order_id,v_user,p_next_status,jsonb_build_object('note',p_note));

 if p_next_status='CONFIRMED' then
   update public.order_groups set status='CONFIRMED' where order_id=p_order_id and status='PAID';
 elsif p_next_status='PREPARING' then
   update public.order_groups set status='PREPARING' where order_id=p_order_id and status='CONFIRMED';
 elsif p_next_status='READY_FOR_PICKUP' then
   update public.order_groups set status='READY_FOR_PICKUP' where order_id=p_order_id and status='PREPARING';
 elsif p_next_status='CANCELLED' then
   update public.order_groups set status='CANCELLED'
   where order_id=p_order_id and status not in ('DELIVERED','CANCELLED');
 end if;

 return true;
end;
$$;
revoke all on function public.transition_order_status(uuid,public.order_status,text) from public,anon,authenticated;
grant execute on function public.transition_order_status(uuid,public.order_status,text) to service_role;

create or replace function public.consume_order_inventory(
  p_order_id uuid
) returns integer
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_count integer:=0;
 v_item record;
begin
 if p_order_id is null then raise exception 'order_required'; end if;
 for v_item in
   select oi.product_id,oi.quantity
   from public.order_items oi
   join public.order_groups og on og.id=oi.order_group_id
   where og.order_id=p_order_id
 loop
   perform public.consume_reserved_inventory(v_item.product_id,v_item.quantity);
   v_count:=v_count+1;
 end loop;
 return v_count;
end;
$$;
revoke all on function public.consume_order_inventory(uuid) from public,anon,authenticated;
grant execute on function public.consume_order_inventory(uuid) to service_role;
