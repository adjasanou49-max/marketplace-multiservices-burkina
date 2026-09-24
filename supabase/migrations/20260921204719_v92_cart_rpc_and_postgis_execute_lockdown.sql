
create or replace function public.add_to_cart(
  p_product_id uuid,
  p_quantity integer,
  p_variant_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid;
  v_cart_id uuid;
  v_item_id uuid;
  v_existing_qty integer;
  v_available integer;
  v_unit_price numeric;
  v_variant_product_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity <= 0 or p_quantity > 1000 then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;

  perform 1 from public.profiles where id = v_user_id for update;
  if not found then
    raise exception 'profile_not_found' using errcode = '23503';
  end if;

  select p.price
    into v_unit_price
  from public.products p
  where p.id = p_product_id
    and p.status = 'ACTIVE'::public.product_status
    and not (
      p.is_expirable
      and p.expiry_date is not null
      and p.expiry_date < current_date
    )
  for share;

  if v_unit_price is null then
    raise exception 'product_unavailable' using errcode = 'P0001';
  end if;

  if p_variant_id is not null then
    select pv.product_id, coalesce(pv.price, v_unit_price)
      into v_variant_product_id, v_unit_price
    from public.product_variants pv
    where pv.id = p_variant_id
    for share;

    if v_variant_product_id is null or v_variant_product_id <> p_product_id then
      raise exception 'invalid_variant' using errcode = '22023';
    end if;
  end if;

  select (i.quantity - i.reserved_quantity)
    into v_available
  from public.inventory i
  where i.product_id = p_product_id
  for share;

  if v_available is not null then
    select coalesce(ci.quantity, 0)
      into v_existing_qty
    from public.carts c
    left join public.cart_items ci
      on ci.cart_id = c.id
     and ci.product_id = p_product_id
     and coalesce(ci.variant_id, '00000000-0000-0000-0000-000000000000'::uuid)
         = coalesce(p_variant_id, '00000000-0000-0000-0000-000000000000'::uuid)
    where c.customer_id = v_user_id
      and c.status = 'ACTIVE'
    for share;

    if coalesce(v_existing_qty, 0) + p_quantity > v_available then
      raise exception 'insufficient_stock' using errcode = 'P0001';
    end if;
  end if;

  select id
    into v_cart_id
  from public.carts
  where customer_id = v_user_id
    and status = 'ACTIVE'
  for update;

  if v_cart_id is null then
    insert into public.carts(customer_id, status)
    values (v_user_id, 'ACTIVE')
    returning id into v_cart_id;
  end if;

  insert into public.cart_items(cart_id, product_id, variant_id, quantity, unit_price)
  values (v_cart_id, p_product_id, p_variant_id, p_quantity, v_unit_price)
  on conflict (cart_id, product_id, coalesce(variant_id, '00000000-0000-0000-0000-000000000000'::uuid))
  do update
    set quantity = public.cart_items.quantity + excluded.quantity,
        unit_price = excluded.unit_price
  returning id into v_item_id;

  update public.carts
     set updated_at = now()
   where id = v_cart_id;

  return v_item_id;
end;
$$;

revoke all on function public.add_to_cart(uuid, integer, uuid) from public;
revoke all on function public.add_to_cart(uuid, integer, uuid) from anon;
revoke all on function public.add_to_cart(uuid, integer, uuid) from authenticated;
grant execute on function public.add_to_cart(uuid, integer, uuid) to authenticated;

revoke all on function public.st_estimatedextent(text, text) from public;
revoke all on function public.st_estimatedextent(text, text) from anon;
revoke all on function public.st_estimatedextent(text, text) from authenticated;

revoke all on function public.st_estimatedextent(text, text, text) from public;
revoke all on function public.st_estimatedextent(text, text, text) from anon;
revoke all on function public.st_estimatedextent(text, text, text) from authenticated;

revoke all on function public.st_estimatedextent(text, text, text, boolean) from public;
revoke all on function public.st_estimatedextent(text, text, text, boolean) from anon;
revoke all on function public.st_estimatedextent(text, text, text, boolean) from authenticated;
