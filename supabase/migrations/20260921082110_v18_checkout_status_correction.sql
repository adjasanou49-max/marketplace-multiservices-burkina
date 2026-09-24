
create or replace function public.checkout_active_cart(
  p_cart_id uuid,
  p_delivery_fee numeric default 0,
  p_delivery_address jsonb default null
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_user uuid := (select auth.uid());
  v_order_id uuid;
  v_group_id uuid;
  v_cart record;
  v_item record;
  v_price numeric;
  v_subtotal numeric := 0;
  v_group_subtotal numeric := 0;
  v_seen_shop uuid := null;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_delivery_fee < 0 then raise exception 'invalid_delivery_fee'; end if;

  select * into v_cart from public.carts
  where id=p_cart_id and customer_id=v_user and status='ACTIVE' for update;
  if not found then raise exception 'active_cart_not_found'; end if;
  if not exists (select 1 from public.cart_items where cart_id=p_cart_id) then raise exception 'cart_empty'; end if;

  insert into public.orders(customer_id,status,subtotal,delivery_fee,discount_total,total,currency,delivery_address)
  values(v_user,'PENDING_PAYMENT',0,p_delivery_fee,0,p_delivery_fee,'XOF',p_delivery_address)
  returning id into v_order_id;

  for v_item in
    select ci.*, p.shop_id, p.name as current_product_name, p.price as product_price,
           p.status as product_status, p.is_expirable, p.expiry_date,
           pv.price as variant_price, pv.name as variant_name
    from public.cart_items ci
    join public.products p on p.id=ci.product_id
    left join public.product_variants pv on pv.id=ci.variant_id and pv.product_id=ci.product_id
    where ci.cart_id=p_cart_id
    order by p.shop_id, ci.id
  loop
    if v_item.quantity <= 0 then raise exception 'invalid_quantity'; end if;
    if v_item.product_status <> 'ACTIVE' then raise exception 'product_not_active'; end if;
    if v_item.is_expirable and v_item.expiry_date is not null and v_item.expiry_date < current_date then raise exception 'product_expired'; end if;
    if v_item.variant_id is not null and v_item.variant_price is null then raise exception 'invalid_variant'; end if;

    v_price := coalesce(v_item.variant_price, v_item.product_price);
    if v_price is null or v_price < 0 then raise exception 'invalid_product_price'; end if;

    if v_seen_shop is distinct from v_item.shop_id then
      if v_seen_shop is not null then
        insert into public.order_packages(order_group_id,status) values(v_group_id,'CREATED');
      end if;
      insert into public.order_groups(order_id,shop_id,status,subtotal)
      values(v_order_id,v_item.shop_id,'PENDING_PAYMENT',0)
      returning id into v_group_id;
      v_seen_shop := v_item.shop_id;
      v_group_subtotal := 0;
    end if;

    if not public.reserve_inventory(v_item.product_id,v_item.quantity) then raise exception 'insufficient_inventory'; end if;

    insert into public.order_items(order_group_id,product_id,variant_id,product_name,quantity,unit_price,total_price)
    values(v_group_id,v_item.product_id,v_item.variant_id,
      case when v_item.variant_id is null then v_item.current_product_name
           else v_item.current_product_name || ' - ' || coalesce(v_item.variant_name,'Variant') end,
      v_item.quantity,v_price,v_price*v_item.quantity);

    v_group_subtotal := v_group_subtotal + v_price*v_item.quantity;
    v_subtotal := v_subtotal + v_price*v_item.quantity;
    update public.order_groups set subtotal=v_group_subtotal where id=v_group_id;
  end loop;

  insert into public.order_packages(order_group_id,status) values(v_group_id,'CREATED');

  update public.orders
  set subtotal=v_subtotal,total=v_subtotal+p_delivery_fee,status='PENDING_PAYMENT',updated_at=now()
  where id=v_order_id;

  update public.carts set status='CHECKED_OUT',updated_at=now() where id=p_cart_id;
  return v_order_id;
end
$$;
revoke execute on function public.checkout_active_cart(uuid,numeric,jsonb) from public,anon,authenticated;
