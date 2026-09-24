
create or replace function public.create_seller_shop(
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
as $function$
declare
  v_user uuid := (select auth.uid());
  v_seller_id uuid;
  v_shop_id uuid;
  v_name text := trim(coalesce(p_name, ''));
  v_normalized text;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  if length(v_name) < 2 or length(v_name) > 120 then
    raise exception 'shop_name_invalid';
  end if;

  v_normalized := public.normalize_shop_name(v_name);
  if length(v_normalized) < 2 then
    raise exception 'shop_name_invalid';
  end if;

  select id
  into v_seller_id
  from public.sellers
  where user_id = v_user
  limit 1;

  if v_seller_id is null then
    raise exception 'seller_profile_required';
  end if;

  if exists (
    select 1
    from public.shops
    where normalized_name = v_normalized
  ) then
    raise exception 'shop_name_taken';
  end if;

  insert into public.shops(
    seller_id,
    name,
    normalized_name,
    logo_url,
    cover_url,
    description,
    phone,
    address,
    status,
    verification_status
  )
  values(
    v_seller_id,
    v_name,
    v_normalized,
    nullif(trim(coalesce(p_logo_url, '')), ''),
    nullif(trim(coalesce(p_cover_url, '')), ''),
    nullif(trim(coalesce(p_description, '')), ''),
    nullif(trim(coalesce(p_phone, '')), ''),
    nullif(trim(coalesce(p_address, '')), ''),
    'PENDING_REVIEW',
    'PENDING'
  )
  returning id into v_shop_id;

  return v_shop_id;
exception
  when unique_violation then
    raise exception 'shop_name_taken';
end;
$function$;

revoke execute on function public.create_seller_shop(text, text, text, text, text, text) from anon, public;
grant execute on function public.create_seller_shop(text, text, text, text, text, text) to authenticated;
