
create or replace function public.normalize_shop_name(p_name text)
returns text
language sql immutable
set search_path = pg_catalog
as $$
 select lower(regexp_replace(trim(p_name), '[^[:alnum:][:space:]]+', '', 'g'))
$$;

create or replace function public.prevent_expired_product_activation()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
 if new.is_expirable and new.expiry_date is not null and new.expiry_date < current_date
    and new.status = 'ACTIVE' then
   raise exception 'expired_product_cannot_be_active';
 end if;
 return new;
end;
$$;

drop trigger if exists trg_prevent_expired_product_activation on public.products;
create trigger trg_prevent_expired_product_activation
before insert or update of expiry_date,is_expirable,status on public.products
for each row execute function public.prevent_expired_product_activation();

create or replace function public.set_shop_normalized_name()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
 new.normalized_name := public.normalize_shop_name(new.name);
 return new;
end;
$$;

drop trigger if exists trg_set_shop_normalized_name on public.shops;
create trigger trg_set_shop_normalized_name
before insert or update of name on public.shops
for each row execute function public.set_shop_normalized_name();

revoke execute on function public.normalize_shop_name(text) from anon, authenticated;
