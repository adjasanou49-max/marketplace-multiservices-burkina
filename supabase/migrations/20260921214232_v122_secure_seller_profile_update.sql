
create or replace function public.update_seller_profile(
  p_business_name text,
  p_business_phone text
)
returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_user uuid := (select auth.uid());
  v_seller uuid;
  v_name text := nullif(trim(coalesce(p_business_name,'')),'');
  v_phone text := nullif(trim(coalesce(p_business_phone,'')),'');
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select id into v_seller from public.sellers where user_id=v_user limit 1;
  if v_seller is null then raise exception 'seller_not_found'; end if;

  if v_name is not null and (length(v_name) < 2 or length(v_name) > 160) then
    raise exception 'business_name_invalid';
  end if;
  if v_phone is not null and length(v_phone) > 32 then
    raise exception 'business_phone_invalid';
  end if;

  update public.sellers
  set business_name=v_name,
      business_phone=v_phone,
      updated_at=now()
  where id=v_seller
  returning id into v_seller;

  return v_seller;
end;
$$;

revoke all on function public.update_seller_profile(text,text) from public,anon;
grant execute on function public.update_seller_profile(text,text) to authenticated;
