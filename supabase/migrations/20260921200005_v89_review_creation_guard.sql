create or replace function public.create_review(
  p_product_id uuid,
  p_shop_id uuid,
  p_rating integer,
  p_body text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_review uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_rating is null or p_rating < 1 or p_rating > 5 then
    raise exception 'invalid_rating';
  end if;

  if not exists (
    select 1
    from public.order_items oi
    join public.order_groups og on og.id = oi.order_group_id
    join public.orders o on o.id = og.order_id
    join public.products p on p.id = oi.product_id
    where o.customer_id = v_user
      and og.status = 'DELIVERED'
      and oi.product_id = p_product_id
      and og.shop_id = p_shop_id
  ) then
    raise exception 'product_not_delivered_to_customer';
  end if;

  insert into public.reviews(
    customer_id, product_id, shop_id, rating, body, status
  )
  values(
    v_user, p_product_id, p_shop_id, p_rating,
    nullif(trim(p_body), ''),
    'PENDING'
  )
  returning id into v_review;

  return v_review;
exception
  when unique_violation then
    raise exception 'review_already_exists';
end;
$function$;

revoke all on function public.create_review(uuid,uuid,integer,text) from public, anon;
grant execute on function public.create_review(uuid,uuid,integer,text) to authenticated;
