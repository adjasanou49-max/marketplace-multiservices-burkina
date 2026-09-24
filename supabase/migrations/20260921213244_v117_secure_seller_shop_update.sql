
drop policy if exists shops_owner_update on public.shops;

create or replace function public.update_seller_shop(
  p_shop_id uuid,
  p_name text,
  p_description text default null,
  p_phone text default null,
  p_address text default null,
  p_logo_url text default null,
  p_cover_url text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := (select auth.uid());
  v_seller_id uuid;
  v_name text := trim(coalesce(p_name,''));
  v_normalized text;
  v_old_normalized text;
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select id into v_seller_id from public.sellers where user_id=v_user limit 1;
  if v_seller_id is null then raise exception 'seller_profile_required'; end if;
  if p_shop_id is null then raise exception 'shop_required'; end if;
  if length(v_name) < 2 or length(v_name) > 120 then raise exception 'shop_name_invalid'; end if;

  select normalized_name into v_old_normalized
  from public.shops
  where id=p_shop_id and seller_id=v_seller_id
  for update;

  if not found then raise exception 'shop_not_owned'; end if;

  v_normalized := public.normalize_shop_name(v_name);
  if length(v_normalized) < 2 then raise exception 'shop_name_invalid'; end if;

  if v_normalized <> v_old_normalized and exists(
    select 1 from public.shops
    where normalized_name=v_normalized and id<>p_shop_id
  ) then
    raise exception 'shop_name_taken';
  end if;

  update public.shops
  set name=v_name,
      normalized_name=v_normalized,
      description=nullif(trim(coalesce(p_description,'')),''),
      phone=nullif(trim(coalesce(p_phone,'')),''),
      address=nullif(trim(coalesce(p_address,'')),''),
      logo_url=nullif(trim(coalesce(p_logo_url,'')),''),
      cover_url=nullif(trim(coalesce(p_cover_url,'')),''),
      status='PENDING_REVIEW',
      verification_status='PENDING',
      updated_at=now()
  where id=p_shop_id and seller_id=v_seller_id
  returning id into v_id;

  return v_id;
exception
  when unique_violation then
    raise exception 'shop_name_taken';
end;
$$;

revoke all on function public.update_seller_shop(uuid,text,text,text,text,text,text) from public,anon;
grant execute on function public.update_seller_shop(uuid,text,text,text,text,text,text) to authenticated;
