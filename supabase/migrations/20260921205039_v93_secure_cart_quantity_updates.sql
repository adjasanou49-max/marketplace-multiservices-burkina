
create or replace function public.set_cart_item_quantity(
  p_cart_item_id uuid,
  p_quantity integer
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_product_id uuid;
  v_cart_id uuid;
  v_available integer;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity < 0 or p_quantity > 1000 then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;

  select ci.cart_id, ci.product_id
    into v_cart_id, v_product_id
  from public.cart_items ci
  join public.carts c on c.id = ci.cart_id
  where ci.id = p_cart_item_id
    and c.customer_id = v_user_id
    and c.status = 'ACTIVE'
  for update of ci, c;

  if v_cart_id is null then
    raise exception 'cart_item_not_found' using errcode = 'P0002';
  end if;

  if p_quantity = 0 then
    delete from public.cart_items where id = p_cart_item_id;

    update public.carts
       set updated_at = now()
     where id = v_cart_id;

    return;
  end if;

  if exists (
    select 1
    from public.products p
    where p.id = v_product_id
      and p.status = 'ACTIVE'::public.product_status
      and (
        not p.is_expirable
        or p.expiry_date is null
        or p.expiry_date >= current_date
      )
  ) = false then
    raise exception 'product_unavailable' using errcode = 'P0001';
  end if;

  select i.quantity - i.reserved_quantity
    into v_available
  from public.inventory i
  where i.product_id = v_product_id
  for share;

  if v_available is not null and p_quantity > v_available then
    raise exception 'insufficient_stock' using errcode = 'P0001';
  end if;

  update public.cart_items
     set quantity = p_quantity
   where id = p_cart_item_id;

  update public.carts
     set updated_at = now()
   where id = v_cart_id;
end;
$$;

revoke all on function public.set_cart_item_quantity(uuid, integer) from public;
revoke all on function public.set_cart_item_quantity(uuid, integer) from anon;
revoke all on function public.set_cart_item_quantity(uuid, integer) from authenticated;
grant execute on function public.set_cart_item_quantity(uuid, integer) to authenticated;
