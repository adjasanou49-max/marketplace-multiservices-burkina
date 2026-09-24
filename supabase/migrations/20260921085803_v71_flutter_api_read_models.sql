
create or replace function public.get_home_catalog(p_category_id uuid default null,p_limit integer default 20,p_offset integer default 0)
returns table(
 product_id uuid, shop_id uuid, category_id uuid, product_name text, price numeric,
 compare_at_price numeric, shop_name text, image_path text, inventory_quantity integer
)
language sql stable security invoker
set search_path=pg_catalog,public
as $$
 select p.id,p.shop_id,p.category_id,p.name,p.price,p.compare_at_price,
        sh.name,pi.storage_path,i.quantity
 from public.products p
 join public.shops sh on sh.id=p.shop_id
 left join lateral (
   select storage_path from public.product_images x
   where x.product_id=p.id order by x.sort_order asc limit 1
 ) pi on true
 left join public.inventory i on i.product_id=p.id
 where p.status='ACTIVE'
   and sh.status='ACTIVE'
   and sh.verification_status='VERIFIED'
   and (p_category_id is null or p.category_id=p_category_id)
   and (not p.is_expirable or p.expiry_date is null or p.expiry_date >= current_date)
   and coalesce(i.quantity,0) > 0
 order by p.created_at desc
 limit greatest(1,least(p_limit,100))
 offset greatest(0,p_offset);
$$;
revoke all on function public.get_home_catalog(uuid,integer,integer) from public,anon;
grant execute on function public.get_home_catalog(uuid,integer,integer) to authenticated;

create or replace function public.get_my_orders(p_limit integer default 20,p_offset integer default 0)
returns table(order_id uuid,status public.order_status,total numeric,currency text,created_at timestamptz)
language sql stable security invoker
set search_path=pg_catalog,public
as $$
 select id,status,total,currency::text,created_at
 from public.orders
 where customer_id=(select auth.uid())
 order by created_at desc
 limit greatest(1,least(p_limit,100))
 offset greatest(0,p_offset);
$$;
revoke all on function public.get_my_orders(integer,integer) from public,anon;
grant execute on function public.get_my_orders(integer,integer) to authenticated;

create or replace function public.get_my_cart()
returns table(cart_id uuid,status text,item_count bigint,subtotal numeric)
language sql stable security invoker
set search_path=pg_catalog,public
as $$
 select c.id,c.status::text,count(ci.id),
        coalesce(sum(ci.unit_price*ci.quantity),0)
 from public.carts c
 left join public.cart_items ci on ci.cart_id=c.id
 where c.customer_id=(select auth.uid()) and c.status='ACTIVE'
 group by c.id,c.status;
$$;
revoke all on function public.get_my_cart() from public,anon;
grant execute on function public.get_my_cart() to authenticated;
