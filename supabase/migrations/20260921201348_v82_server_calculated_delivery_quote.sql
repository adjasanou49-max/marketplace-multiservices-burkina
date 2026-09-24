
create or replace function public.calculate_delivery_fee(
  p_cart_id uuid,
  p_delivery_address jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, extensions
as $function$
declare
  v_user uuid := (select auth.uid());
  v_lat double precision;
  v_lon double precision;
  v_distance numeric := 0;
  v_stop_count integer := 0;
  v_base_fee numeric := 0;
  v_per_km_fee numeric := 0;
  v_per_stop_fee numeric := 0;
  v_customer_fee numeric := 0;
  v_rule_id uuid;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  if p_cart_id is null then
    raise exception 'cart_required';
  end if;

  perform 1
  from public.carts
  where id = p_cart_id
    and customer_id = v_user
    and status = 'ACTIVE';
  if not found then
    raise exception 'cart_not_active_or_not_owned';
  end if;

  v_lat := nullif(p_delivery_address ->> 'latitude', '')::double precision;
  v_lon := nullif(p_delivery_address ->> 'longitude', '')::double precision;

  select count(distinct p.shop_id)::integer
    into v_stop_count
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  where ci.cart_id = p_cart_id
    and p.status = 'ACTIVE';

  if v_lat is not null and v_lon is not null then
    select coalesce(
      max(
        extensions.st_distance(
          s.location,
          extensions.st_setsrid(
            extensions.st_makepoint(v_lon, v_lat),
            4326
          )::extensions.geography
        ) / 1000
      ),
      0
    )
    into v_distance
    from public.cart_items ci
    join public.products p on p.id = ci.product_id
    join public.shops s on s.id = p.shop_id
    where ci.cart_id = p_cart_id
      and p.status = 'ACTIVE'
      and s.location is not null;
  end if;

  select id, base_fee, per_km_fee, per_stop_fee
    into v_rule_id, v_base_fee, v_per_km_fee, v_per_stop_fee
  from public.delivery_pricing_rules
  where active = true
    and min_distance_km <= v_distance
    and (max_distance_km is null or v_distance <= max_distance_km)
  order by min_distance_km desc
  limit 1;

  if v_rule_id is null then
    raise exception 'delivery_pricing_not_configured';
  end if;

  v_customer_fee := greatest(
    0,
    round(
      v_base_fee
      + (v_distance * v_per_km_fee)
      + greatest(v_stop_count - 1, 0) * v_per_stop_fee,
      0
    )
  );

  return jsonb_build_object(
    'customer_fee', v_customer_fee,
    'distance_km', round(v_distance, 2),
    'stop_count', greatest(v_stop_count, 1),
    'pricing_rule_id', v_rule_id,
    'currency', 'XOF'
  );
end;
$function$;

revoke execute on function public.calculate_delivery_fee(uuid, jsonb) from anon;
grant execute on function public.calculate_delivery_fee(uuid, jsonb) to authenticated;

create or replace function public.apply_checkout_delivery_fee()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $function$
declare
  v_cart_id uuid;
  v_quote jsonb;
begin
  if new.status <> 'PENDING_PAYMENT' then
    return new;
  end if;

  select id
    into v_cart_id
  from public.carts
  where customer_id = new.customer_id
    and status = 'ACTIVE'
  order by updated_at desc
  limit 1;

  if v_cart_id is null then
    return new;
  end if;

  v_quote := public.calculate_delivery_fee(v_cart_id, new.delivery_address);
  new.delivery_fee := coalesce((v_quote ->> 'customer_fee')::numeric, 0);
  new.total := new.subtotal + new.delivery_fee - new.discount_total;

  return new;
end;
$function$;

drop trigger if exists trg_apply_checkout_delivery_fee on public.orders;
create trigger trg_apply_checkout_delivery_fee
before insert on public.orders
for each row
execute function public.apply_checkout_delivery_fee();

insert into public.delivery_pricing_rules
  (name, min_distance_km, max_distance_km, base_fee, per_km_fee, per_stop_fee, active)
select 'Standard 0-5 km', 0, 5, 1000, 0, 0, true
where not exists (select 1 from public.delivery_pricing_rules);

insert into public.delivery_pricing_rules
  (name, min_distance_km, max_distance_km, base_fee, per_km_fee, per_stop_fee, active)
select 'Standard 5-15 km', 5, 15, 1000, 100, 0, true
where not exists (
  select 1 from public.delivery_pricing_rules where name = 'Standard 5-15 km'
);

insert into public.delivery_pricing_rules
  (name, min_distance_km, max_distance_km, base_fee, per_km_fee, per_stop_fee, active)
select 'Standard 15+ km', 15, null, 2000, 100, 0, true
where not exists (
  select 1 from public.delivery_pricing_rules where name = 'Standard 15+ km'
);
