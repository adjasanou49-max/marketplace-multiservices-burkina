
create or replace function public.get_seller_client_stats()
returns jsonb
language plpgsql
security definer
stable
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := (select auth.uid());
  v_seller_id uuid;
  v_total_clients bigint;
  v_repeat_clients bigint;
  v_total_orders bigint;
  v_delivered_orders bigint;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;

  select id into v_seller_id
  from public.sellers
  where user_id=v_user
  limit 1;

  if v_seller_id is null then raise exception 'seller_not_found'; end if;

  select count(distinct o.customer_id),
         count(*) filter (
           where client_counts.order_count > 1
         )
    into v_total_clients, v_repeat_clients
  from (
    select o.customer_id, count(*) as order_count
    from public.orders o
    join public.order_groups og on og.order_id=o.id
    join public.shops sh on sh.id=og.shop_id
    where sh.seller_id=v_seller_id
      and o.customer_id is not null
      and og.status <> 'CANCELLED'
    group by o.customer_id
  ) client_counts;

  select count(*),
         count(*) filter (where og.status='DELIVERED')
    into v_total_orders, v_delivered_orders
  from public.order_groups og
  join public.shops sh on sh.id=og.shop_id
  where sh.seller_id=v_seller_id;

  return jsonb_build_object(
    'total_clients', coalesce(v_total_clients,0),
    'repeat_clients', coalesce(v_repeat_clients,0),
    'total_orders', coalesce(v_total_orders,0),
    'delivered_orders', coalesce(v_delivered_orders,0)
  );
end;
$$;

revoke all on function public.get_seller_client_stats() from public,anon;
grant execute on function public.get_seller_client_stats() to authenticated;
