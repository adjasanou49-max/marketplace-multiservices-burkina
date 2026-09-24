
create or replace function public.transition_order_status(
  p_order_id uuid,
  p_next_status public.order_status,
  p_note text default null
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
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

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'order_not_found'; end if;

  v_is_customer := v_order.customer_id = v_user;
  v_is_admin := exists (
    select 1 from public.admin_users au
    where au.user_id = v_user and au.active = true
  );
  v_is_seller := exists (
    select 1
    from public.order_groups og
    join public.shops sh on sh.id = og.shop_id
    join public.sellers s on s.id = sh.seller_id
    where og.order_id = p_order_id and s.user_id = v_user
  );

  if p_next_status = 'CANCELLED' then
    v_allowed := (
      (v_is_customer and v_order.status in ('PENDING_PAYMENT','PAID'))
      or v_is_admin
    );
  elsif p_next_status = 'DISPUTED' then
    v_allowed := v_is_customer or v_is_seller or v_is_admin;
  else
    v_allowed := v_is_admin;
  end if;

  if not v_allowed then raise exception 'order_transition_not_allowed'; end if;

  if p_next_status = 'CANCELLED'
     and v_order.status in ('PENDING_PAYMENT','PAID','CONFIRMED','PREPARING') then
    for v_item in
      select oi.product_id, oi.quantity
      from public.order_items oi
      join public.order_groups og on og.id = oi.order_group_id
      where og.order_id = p_order_id
    loop
      perform public.release_inventory(v_item.product_id, v_item.quantity);
    end loop;
  end if;

  update public.orders
  set status = p_next_status, updated_at = now()
  where id = p_order_id;

  insert into public.order_events(order_id, actor_id, status, metadata)
  values (
    p_order_id,
    v_user,
    p_next_status,
    jsonb_build_object('note', p_note)
  );

  if p_next_status = 'CANCELLED' then
    update public.order_groups
    set status = 'CANCELLED'
    where order_id = p_order_id
      and status not in ('DELIVERED','CANCELLED');
  end if;

  return true;
end;
$function$;

create or replace function public.toggle_product_favorite(p_product_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_exists boolean;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;

  if not exists (
    select 1 from public.products
    where id = p_product_id and status = 'ACTIVE'
  ) then
    raise exception 'product_unavailable';
  end if;

  select exists (
    select 1 from public.product_favorites
    where product_id = p_product_id and user_id = v_user
  ) into v_exists;

  if v_exists then
    delete from public.product_favorites
    where product_id = p_product_id and user_id = v_user;
    return false;
  end if;

  insert into public.product_favorites(product_id, user_id)
  values (p_product_id, v_user);
  return true;
end;
$function$;

create or replace function public.toggle_shop_follow(p_shop_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_exists boolean;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;

  if not exists (
    select 1 from public.shops
    where id = p_shop_id and status = 'ACTIVE'
  ) then
    raise exception 'shop_unavailable';
  end if;

  select exists (
    select 1 from public.shop_followers
    where shop_id = p_shop_id and user_id = v_user
  ) into v_exists;

  if v_exists then
    delete from public.shop_followers
    where shop_id = p_shop_id and user_id = v_user;
    return false;
  end if;

  insert into public.shop_followers(shop_id, user_id)
  values (p_shop_id, v_user);
  return true;
end;
$function$;

create or replace function public.my_favorite_products(p_limit integer default 50)
returns table(
  product_id uuid,
  name text,
  price numeric,
  currency text,
  shop_id uuid,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select p.id, p.name, p.price, 'XOF'::text, p.shop_id, pf.created_at
  from public.product_favorites pf
  join public.products p on p.id = pf.product_id
  where pf.user_id = (select auth.uid())
    and p.status = 'ACTIVE'
  order by pf.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
$function$;

create or replace function public.my_followed_shops(p_limit integer default 50)
returns table(
  shop_id uuid,
  name text,
  description text,
  logo_url text,
  cover_url text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select s.id, s.name, s.description, s.logo_url, s.cover_url, sf.created_at
  from public.shop_followers sf
  join public.shops s on s.id = sf.shop_id
  where sf.user_id = (select auth.uid())
    and s.status = 'ACTIVE'
  order by sf.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100));
$function$;

revoke all on function public.toggle_product_favorite(uuid) from public, anon;
grant execute on function public.toggle_product_favorite(uuid) to authenticated;
revoke all on function public.toggle_shop_follow(uuid) from public, anon;
grant execute on function public.toggle_shop_follow(uuid) to authenticated;
revoke all on function public.my_favorite_products(integer) from public, anon;
grant execute on function public.my_favorite_products(integer) to authenticated;
revoke all on function public.my_followed_shops(integer) from public, anon;
grant execute on function public.my_followed_shops(integer) to authenticated;
