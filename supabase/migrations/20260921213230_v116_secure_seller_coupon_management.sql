
create policy coupons_seller_read
on public.coupons for select to authenticated
using (
  seller_id in (
    select s.id from public.sellers s
    where s.user_id = (select auth.uid())
  )
);

create or replace function public.create_seller_coupon(
  p_code text,
  p_discount_type text,
  p_discount_value numeric,
  p_min_order_amount numeric default 0,
  p_max_uses integer default null,
  p_starts_at timestamptz default now(),
  p_ends_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := (select auth.uid());
  v_seller_id uuid;
  v_coupon_id uuid;
  v_code text := upper(trim(coalesce(p_code,'')));
  v_type text := upper(trim(coalesce(p_discount_type,'')));
  v_end timestamptz := coalesce(p_ends_at, now() + interval '30 days');
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select id into v_seller_id from public.sellers where user_id=v_user limit 1;
  if v_seller_id is null then raise exception 'seller_not_found'; end if;
  if length(v_code) < 3 or length(v_code) > 32 then raise exception 'coupon_code_invalid'; end if;
  if v_type not in ('PERCENT','FIXED') then raise exception 'coupon_type_invalid'; end if;
  if p_discount_value is null or p_discount_value <= 0 then raise exception 'discount_value_invalid'; end if;
  if v_type = 'PERCENT' and p_discount_value > 100 then raise exception 'percent_too_high'; end if;
  if p_min_order_amount is null or p_min_order_amount < 0 then raise exception 'min_order_invalid'; end if;
  if p_max_uses is not null and p_max_uses <= 0 then raise exception 'max_uses_invalid'; end if;
  if p_starts_at is null or v_end <= p_starts_at then raise exception 'coupon_dates_invalid'; end if;

  insert into public.coupons(
    seller_id,code,discount_type,discount_value,min_order_amount,max_uses,used_count,starts_at,ends_at,active
  )
  values(
    v_seller_id,v_code,v_type,p_discount_value,p_min_order_amount,p_max_uses,0,p_starts_at,v_end,true
  )
  returning id into v_coupon_id;

  return v_coupon_id;
exception
  when unique_violation then
    raise exception 'coupon_code_already_exists';
end;
$$;

create or replace function public.set_seller_coupon_active(
  p_coupon_id uuid,
  p_active boolean
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := (select auth.uid());
begin
  if v_user is null then raise exception 'not_authenticated'; end if;

  update public.coupons c
  set active=p_active
  where c.id=p_coupon_id
    and c.seller_id in (
      select s.id from public.sellers s where s.user_id=v_user
    );

  if not found then raise exception 'coupon_not_owned'; end if;
end;
$$;

revoke all on function public.create_seller_coupon(text,text,numeric,numeric,integer,timestamptz,timestamptz) from public,anon;
revoke all on function public.set_seller_coupon_active(uuid,boolean) from public,anon;
grant execute on function public.create_seller_coupon(text,text,numeric,numeric,integer,timestamptz,timestamptz) to authenticated;
grant execute on function public.set_seller_coupon_active(uuid,boolean) to authenticated;
