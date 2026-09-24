
create policy promotions_seller_read
on public.promotions for select to authenticated
using (
  seller_id in (
    select s.id from public.sellers s
    where s.user_id=(select auth.uid())
  )
);

create or replace function public.create_seller_promotion(
  p_shop_id uuid,
  p_name text,
  p_promotion_type text,
  p_value numeric,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := (select auth.uid());
  v_seller_id uuid;
  v_id uuid;
  v_type text := upper(trim(coalesce(p_promotion_type,'')));
  v_name text := trim(coalesce(p_name,''));
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select id into v_seller_id from public.sellers where user_id=v_user limit 1;
  if v_seller_id is null then raise exception 'seller_not_found'; end if;
  if p_shop_id is null then raise exception 'shop_required'; end if;
  if not exists(
    select 1 from public.shops
    where id=p_shop_id and seller_id=v_seller_id
  ) then raise exception 'shop_not_owned'; end if;
  if length(v_name) < 2 or length(v_name) > 120 then
    raise exception 'promotion_name_invalid';
  end if;
  if v_type not in ('PERCENT','FIXED','FLASH','BUNDLE') then
    raise exception 'promotion_type_invalid';
  end if;
  if p_value is null or p_value < 0 then raise exception 'promotion_value_invalid'; end if;
  if v_type='PERCENT' and p_value > 100 then raise exception 'percent_too_high'; end if;
  if p_starts_at is null or p_ends_at is null or p_ends_at <= p_starts_at then
    raise exception 'promotion_dates_invalid';
  end if;

  insert into public.promotions(
    seller_id,shop_id,name,promotion_type,value,starts_at,ends_at,active
  )
  values(
    v_seller_id,p_shop_id,v_name,v_type,p_value,p_starts_at,p_ends_at,true
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.set_seller_promotion_active(
  p_promotion_id uuid,
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

  update public.promotions p
  set active=p_active
  where p.id=p_promotion_id
    and p.seller_id in (
      select s.id from public.sellers s where s.user_id=v_user
    );

  if not found then raise exception 'promotion_not_owned'; end if;
end;
$$;

revoke all on function public.create_seller_promotion(uuid,text,text,numeric,timestamptz,timestamptz) from public,anon;
revoke all on function public.set_seller_promotion_active(uuid,boolean) from public,anon;
grant execute on function public.create_seller_promotion(uuid,text,text,numeric,timestamptz,timestamptz) to authenticated;
grant execute on function public.set_seller_promotion_active(uuid,boolean) to authenticated;
