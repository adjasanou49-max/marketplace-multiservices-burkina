
create or replace function public.create_seller_product(
  p_shop_id uuid,
  p_name text,
  p_price numeric,
  p_category_id uuid default null,
  p_description text default null,
  p_initial_stock integer default 0,
  p_is_expirable boolean default false,
  p_expiry_date date default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := auth.uid();
  v_product uuid;
  v_slug_base text;
  v_slug text;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode='42501';
  end if;

  if p_name is null or length(trim(p_name)) < 2 or length(trim(p_name)) > 180 then
    raise exception 'name_invalid' using errcode='22023';
  end if;

  if p_price is null or p_price < 0 then
    raise exception 'price_invalid' using errcode='22023';
  end if;

  if p_initial_stock is null or p_initial_stock < 0 or p_initial_stock > 1000000 then
    raise exception 'stock_invalid' using errcode='22023';
  end if;

  if p_is_expirable and p_expiry_date is null then
    raise exception 'expiry_date_required' using errcode='22023';
  end if;

  if p_is_expirable and p_expiry_date < current_date then
    raise exception 'expiry_date_invalid' using errcode='22023';
  end if;

  if not exists (
    select 1
    from public.shops s
    join public.sellers se on se.id=s.seller_id
    where s.id=p_shop_id
      and se.user_id=v_user
  ) then
    raise exception 'shop_not_owned' using errcode='42501';
  end if;

  if p_category_id is not null and not exists (
    select 1 from public.categories c
    where c.id=p_category_id and c.is_active=true
  ) then
    raise exception 'category_invalid' using errcode='22023';
  end if;

  v_slug_base := regexp_replace(
    lower(trim(p_name)),
    '[^a-z0-9]+',
    '-',
    'g'
  );

  v_slug_base := regexp_replace(v_slug_base, '(^-|-$)', '', 'g');

  if v_slug_base is null or v_slug_base='' then
    v_slug_base := 'produit';
  end if;

  v_slug := v_slug_base || '-' || substring(md5(gen_random_uuid()::text),1,8);

  insert into public.products(
    shop_id, category_id, name, slug, description, price,
    status, is_expirable, expiry_date
  )
  values(
    p_shop_id, p_category_id, trim(p_name), v_slug,
    nullif(trim(coalesce(p_description,'')), ''),
    p_price, 'DRAFT', p_is_expirable, p_expiry_date
  )
  returning id into v_product;

  insert into public.inventory(product_id, quantity, reserved_quantity)
  values(v_product, p_initial_stock, 0);

  return v_product;
end;
$$;

revoke all on function public.create_seller_product(uuid,text,numeric,uuid,text,integer,boolean,date) from public;
revoke all on function public.create_seller_product(uuid,text,numeric,uuid,text,integer,boolean,date) from anon;
revoke all on function public.create_seller_product(uuid,text,numeric,uuid,text,integer,boolean,date) from authenticated;
grant execute on function public.create_seller_product(uuid,text,numeric,uuid,text,integer,boolean,date) to authenticated;

create or replace function public.set_seller_stock(
  p_product_id uuid,
  p_quantity integer
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := auth.uid();
  v_reserved integer;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode='42501';
  end if;

  if p_quantity is null or p_quantity < 0 or p_quantity > 1000000 then
    raise exception 'stock_invalid' using errcode='22023';
  end if;

  if not exists (
    select 1
    from public.products p
    join public.shops sh on sh.id=p.shop_id
    join public.sellers se on se.id=sh.seller_id
    where p.id=p_product_id and se.user_id=v_user
  ) then
    raise exception 'product_not_owned' using errcode='42501';
  end if;

  select reserved_quantity into v_reserved
  from public.inventory
  where product_id=p_product_id
  for update;

  if v_reserved is null then
    insert into public.inventory(product_id,quantity,reserved_quantity)
    values(p_product_id,p_quantity,0);
    return;
  end if;

  if p_quantity < v_reserved then
    raise exception 'stock_below_reserved' using errcode='22023';
  end if;

  update public.inventory
  set quantity=p_quantity, updated_at=now()
  where product_id=p_product_id;
end;
$$;

revoke all on function public.set_seller_stock(uuid,integer) from public;
revoke all on function public.set_seller_stock(uuid,integer) from anon;
revoke all on function public.set_seller_stock(uuid,integer) from authenticated;
grant execute on function public.set_seller_stock(uuid,integer) to authenticated;
