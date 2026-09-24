
create table if not exists public.checkout_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  idempotency_key text not null,
  order_id uuid references public.orders(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(user_id, idempotency_key)
);
alter table public.checkout_requests enable row level security;

create index if not exists idx_checkout_requests_order on public.checkout_requests(order_id);
create index if not exists idx_checkout_requests_user_created on public.checkout_requests(user_id, created_at desc);

drop policy if exists checkout_requests_owner_read on public.checkout_requests;
create policy checkout_requests_owner_read on public.checkout_requests
for select to authenticated
using (user_id = (select auth.uid()));

create or replace function public.checkout_cart(
  p_cart_id uuid,
  p_delivery_address jsonb,
  p_delivery_fee numeric default 0,
  p_coupon_code text default null,
  p_idempotency_key text default null
) returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := (select auth.uid());
  v_existing uuid;
  v_order uuid;
  v_coupon public.coupons%rowtype;
  v_coupon_id uuid;
  v_subtotal numeric := 0;
  v_discount numeric := 0;
  v_total numeric := 0;
  v_coupon_base numeric := 0;
  v_coupon_discount numeric := 0;
  v_item record;
  v_group_id uuid;
  v_package_id uuid;
  v_reserved boolean;
  v_reserved_count integer := 0;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_cart_id is null then raise exception 'cart_required'; end if;
  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'idempotency_key_required';
  end if;
  if p_delivery_fee < 0 then raise exception 'invalid_delivery_fee'; end if;
  if p_delivery_address is null or jsonb_typeof(p_delivery_address) <> 'object' then
    raise exception 'delivery_address_required';
  end if;

  select order_id into v_existing
  from public.checkout_requests
  where user_id = v_user and idempotency_key = p_idempotency_key
  for update;

  if v_existing is not null then
    return v_existing;
  end if;

  perform 1 from public.carts
  where id=p_cart_id and customer_id=v_user and status='ACTIVE'
  for update;
  if not found then raise exception 'cart_not_active_or_not_owned'; end if;

  if not exists (select 1 from public.cart_items where cart_id=p_cart_id) then
    raise exception 'cart_empty';
  end if;

  -- Lock and validate coupon before inventory reservation.
  if p_coupon_code is not null and length(trim(p_coupon_code)) > 0 then
    select * into v_coupon
    from public.coupons
    where code = trim(p_coupon_code)::citext
      and active = true
    for update;

    if not found then raise exception 'coupon_invalid'; end if;
    if v_coupon.starts_at is not null and now() < v_coupon.starts_at then
      raise exception 'coupon_not_started';
    end if;
    if v_coupon.ends_at is not null and now() >= v_coupon.ends_at then
      raise exception 'coupon_expired';
    end if;
    if v_coupon.max_uses is not null and v_coupon.used_count >= v_coupon.max_uses then
      raise exception 'coupon_exhausted';
    end if;
    if exists (select 1 from public.coupon_usage where coupon_id=v_coupon.id and user_id=v_user) then
      raise exception 'coupon_already_used';
    end if;
    v_coupon_id := v_coupon.id;
  end if;

  -- Price is always read from the catalog, never trusted from cart_items.unit_price.
  for v_item in
    select ci.id, ci.product_id, ci.variant_id, ci.quantity,
           p.name, p.price, p.shop_id, p.status, p.is_expirable, p.expiry_date,
           pv.price as variant_price, pv.product_id as variant_product_id
    from public.cart_items ci
    join public.products p on p.id=ci.product_id
    left join public.product_variants pv on pv.id=ci.variant_id
    where ci.cart_id=p_cart_id
    for update of p, ci
  loop
    if v_item.quantity <= 0 then raise exception 'invalid_quantity'; end if;
    if v_item.status <> 'ACTIVE' then raise exception 'product_unavailable'; end if;
    if v_item.is_expirable and (v_item.expiry_date is null or v_item.expiry_date < current_date) then
      raise exception 'product_expired';
    end if;
    if v_item.variant_id is not null and v_item.variant_product_id is distinct from v_item.product_id then
      raise exception 'invalid_variant';
    end if;

    v_subtotal := v_subtotal + coalesce(v_item.variant_price, v_item.price) * v_item.quantity;

    if v_coupon_id is not null and (v_coupon.seller_id is null or v_coupon.seller_id = (
      select s.id from public.sellers s join public.shops sh on sh.seller_id=s.id where sh.id=v_item.shop_id
    )) then
      v_coupon_base := v_coupon_base + coalesce(v_item.variant_price, v_item.price) * v_item.quantity;
    end if;
  end loop;

  if v_coupon_id is not null then
    if v_coupon_base < v_coupon.min_order_amount then
      raise exception 'coupon_minimum_not_reached';
    end if;
    if v_coupon.discount_type = 'PERCENT' then
      v_coupon_discount := round(v_coupon_base * v_coupon.discount_value / 100, 2);
    elsif v_coupon.discount_type = 'FIXED' then
      v_coupon_discount := least(v_coupon.discount_value, v_coupon_base);
    else
      raise exception 'coupon_type_invalid';
    end if;
    v_discount := least(v_coupon_discount, v_subtotal);
  end if;

  v_total := v_subtotal + p_delivery_fee - v_discount;
  if v_total < 0 then raise exception 'invalid_order_total'; end if;

  insert into public.orders(customer_id,status,subtotal,delivery_fee,discount_total,total,currency,delivery_address)
  values(v_user,'PENDING_PAYMENT',v_subtotal,p_delivery_fee,v_discount,v_total,'XOF',p_delivery_address)
  returning id into v_order;

  for v_item in
    select ci.product_id, ci.variant_id, ci.quantity,
           p.name, p.shop_id, p.price, pv.price as variant_price
    from public.cart_items ci
    join public.products p on p.id=ci.product_id
    left join public.product_variants pv on pv.id=ci.variant_id
    where ci.cart_id=p_cart_id
    order by p.shop_id
  loop
    select id into v_group_id
    from public.order_groups
    where order_id=v_order and shop_id=v_item.shop_id;

    if v_group_id is null then
      insert into public.order_groups(order_id,shop_id,status,subtotal)
      values(v_order,v_item.shop_id,'PENDING_PAYMENT',0)
      returning id into v_group_id;
      insert into public.order_packages(order_group_id,status)
      values(v_group_id,'CREATED')
      returning id into v_package_id;
    end if;

    insert into public.order_items(order_group_id,product_id,variant_id,product_name,quantity,unit_price,total_price)
    values(
      v_group_id,v_item.product_id,v_item.variant_id,v_item.name,v_item.quantity,
      coalesce(v_item.variant_price,v_item.price),
      coalesce(v_item.variant_price,v_item.price)*v_item.quantity
    );

    update public.order_groups
    set subtotal = subtotal + coalesce(v_item.variant_price,v_item.price)*v_item.quantity
    where id=v_group_id;

    select public.reserve_inventory(v_item.product_id,v_item.quantity) into v_reserved;
    if not v_reserved then raise exception 'insufficient_inventory'; end if;
    v_reserved_count := v_reserved_count + 1;
  end loop;

  if v_coupon_id is not null then
    insert into public.coupon_usage(coupon_id,user_id,order_id)
    values(v_coupon_id,v_user,v_order);
    update public.coupons set used_count=used_count+1 where id=v_coupon_id;
  end if;

  update public.carts set status='CHECKED_OUT', updated_at=now() where id=p_cart_id;
  insert into public.order_events(order_id,actor_id,status,metadata)
  values(v_order,v_user,'PENDING_PAYMENT',
         jsonb_build_object('source','checkout','cart_id',p_cart_id,'coupon_id',v_coupon_id));

  insert into public.checkout_requests(user_id,idempotency_key,order_id)
  values(v_user,p_idempotency_key,v_order);

  return v_order;
exception when others then
  raise;
end;
$$;

revoke all on function public.checkout_cart(uuid,jsonb,numeric,text,text) from public, anon, authenticated;
grant execute on function public.checkout_cart(uuid,jsonb,numeric,text,text) to service_role;
