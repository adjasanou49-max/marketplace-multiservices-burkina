
create or replace function public.product_expiry_status(p_expiry_date date)
returns public.expiry_status
language sql stable
set search_path = pg_catalog, public
as $$
 select case
   when p_expiry_date is null then 'NORMAL'::public.expiry_status
   when p_expiry_date < current_date then 'EXPIRED'::public.expiry_status
   when p_expiry_date <= current_date + 30 then 'EXPIRING_SOON'::public.expiry_status
   else 'NORMAL'::public.expiry_status
 end
$$;

create or replace function public.is_expiring_soon(p_expiry_date date)
returns boolean
language sql stable
set search_path = pg_catalog, public
as $$
 select p_expiry_date is not null and p_expiry_date between current_date + 5 and current_date + 30
$$;

create or replace function public.reserve_inventory(p_product_id uuid, p_quantity integer)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_ok boolean;
begin
 if p_quantity <= 0 then raise exception 'quantity_must_be_positive'; end if;
 update public.inventory
 set reserved_quantity = reserved_quantity + p_quantity, updated_at = now()
 where product_id = p_product_id
   and quantity - reserved_quantity >= p_quantity;
 get diagnostics v_ok = row_count;
 return v_ok;
end;
$$;

create or replace function public.release_inventory(p_product_id uuid, p_quantity integer)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_ok boolean;
begin
 if p_quantity <= 0 then raise exception 'quantity_must_be_positive'; end if;
 update public.inventory
 set reserved_quantity = greatest(0, reserved_quantity - p_quantity), updated_at = now()
 where product_id = p_product_id
   and reserved_quantity >= p_quantity;
 get diagnostics v_ok = row_count;
 return v_ok;
end;
$$;

create or replace function public.consume_reserved_inventory(p_product_id uuid, p_quantity integer)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_ok boolean;
begin
 if p_quantity <= 0 then raise exception 'quantity_must_be_positive'; end if;
 update public.inventory
 set quantity = quantity - p_quantity,
     reserved_quantity = reserved_quantity - p_quantity,
     updated_at = now()
 where product_id = p_product_id
   and reserved_quantity >= p_quantity
   and quantity >= p_quantity;
 get diagnostics v_ok = row_count;
 return v_ok;
end;
$$;

revoke execute on function public.reserve_inventory(uuid,integer) from anon, authenticated;
revoke execute on function public.release_inventory(uuid,integer) from anon, authenticated;
revoke execute on function public.consume_reserved_inventory(uuid,integer) from anon, authenticated;
