
create or replace function public.get_seller_dashboard()
returns table(shop_id uuid,shop_name text,active_products bigint,pending_orders bigint,delivered_orders bigint,gross_sales numeric)
language sql stable security invoker set search_path=pg_catalog,public as $$
 select sh.id,sh.name,
 (select count(*) from public.products p where p.shop_id=sh.id and p.status='ACTIVE'),
 (select count(*) from public.order_groups og where og.shop_id=sh.id and og.status in ('PAID','CONFIRMED','PREPARING','READY_FOR_PICKUP')),
 (select count(*) from public.order_groups og where og.shop_id=sh.id and og.status='DELIVERED'),
 coalesce((select sum(og.subtotal) from public.order_groups og where og.shop_id=sh.id and og.status='DELIVERED'),0)
 from public.shops sh join public.sellers s on s.id=sh.seller_id where s.user_id=(select auth.uid());
$$;
revoke all on function public.get_seller_dashboard() from public,anon;
grant execute on function public.get_seller_dashboard() to authenticated;

create or replace function public.get_courier_dashboard()
returns table(assignment_id uuid,package_id uuid,status public.delivery_status,assigned_at timestamptz,shop_name text)
language sql stable security invoker set search_path=pg_catalog,public as $$
 select da.id,da.package_id,da.status,da.assigned_at,sh.name
 from public.delivery_assignments da join public.order_packages op on op.id=da.package_id
 join public.order_groups og on og.id=op.order_group_id join public.shops sh on sh.id=og.shop_id
 where da.courier_id=(select auth.uid()) and da.status not in ('CANCELLED')
 order by da.assigned_at desc;
$$;
revoke all on function public.get_courier_dashboard() from public,anon;
grant execute on function public.get_courier_dashboard() to authenticated;

create or replace function public.get_admin_dashboard()
returns jsonb language sql stable security invoker set search_path=pg_catalog,public as $$
 select jsonb_build_object(
 'users',(select count(*) from public.profiles),
 'sellers',(select count(*) from public.sellers),
 'shops',(select count(*) from public.shops),
 'active_products',(select count(*) from public.products where status='ACTIVE'),
 'orders',(select count(*) from public.orders),
 'open_support',(select count(*) from public.support_tickets where status not in ('RESOLVED','CLOSED')),
 'fraud_reports',(select count(*) from public.fraud_reports where status not in ('RESOLVED','CLOSED'))
 );
$$;
revoke all on function public.get_admin_dashboard() from public,anon,authenticated;
grant execute on function public.get_admin_dashboard() to service_role;
