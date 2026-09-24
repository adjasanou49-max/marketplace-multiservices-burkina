
create or replace function public.calculate_delivery_fee(
  p_cart_id uuid,
  p_delivery_address jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
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

  v_lat := nullif(trim(p_delivery_address ->> 'latitude'), '')::double precision;
  v_lon := nullif(trim(p_delivery_address ->> 'longitude'), '')::double precision;

  if v_lat is not null and (v_lat < -90 or v_lat > 90) then
    raise exception 'latitude_invalid';
  end if;

  if v_lon is not null and (v_lon < -180 or v_lon > 180) then
    raise exception 'longitude_invalid';
  end if;

  select count(distinct p.shop_id)::integer
    into v_stop_count
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  where ci.cart_id = p_cart_id
    and p.status = 'ACTIVE';

  if v_lat is not null and v_lon is not null then
    select coalesce(
      max(
        public.st_distance(
          s.location,
          public.st_setsrid(
            public.st_makepoint(v_lon, v_lat),
            4326
          )::public.geography,
          true
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

revoke execute on function public.calculate_delivery_fee(uuid, jsonb) from anon, public;
grant execute on function public.calculate_delivery_fee(uuid, jsonb) to authenticated;
