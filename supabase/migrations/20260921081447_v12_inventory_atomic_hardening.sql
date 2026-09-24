
create or replace function public.reserve_inventory(p_product_id uuid, p_quantity integer)
returns boolean language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare v_rows integer;
begin
 if p_quantity <= 0 then raise exception 'quantity_must_be_positive'; end if;
 update public.inventory
 set reserved_quantity = reserved_quantity + p_quantity, updated_at = now()
 where product_id = p_product_id
   and quantity - reserved_quantity >= p_quantity;
 get diagnostics v_rows = row_count;
 return v_rows = 1;
end $$;

create or replace function public.release_inventory(p_product_id uuid, p_quantity integer)
returns boolean language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare v_rows integer;
begin
 if p_quantity <= 0 then raise exception 'quantity_must_be_positive'; end if;
 update public.inventory
 set reserved_quantity = reserved_quantity - p_quantity, updated_at = now()
 where product_id = p_product_id and reserved_quantity >= p_quantity;
 get diagnostics v_rows = row_count;
 return v_rows = 1;
end $$;

create or replace function public.consume_reserved_inventory(p_product_id uuid, p_quantity integer)
returns boolean language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare v_rows integer;
begin
 if p_quantity <= 0 then raise exception 'quantity_must_be_positive'; end if;
 update public.inventory
 set quantity = quantity - p_quantity,
     reserved_quantity = reserved_quantity - p_quantity,
     updated_at = now()
 where product_id = p_product_id
   and reserved_quantity >= p_quantity
   and quantity >= p_quantity;
 get diagnostics v_rows = row_count;
 return v_rows = 1;
end $$;

revoke execute on function public.reserve_inventory(uuid,integer) from public, anon, authenticated;
revoke execute on function public.release_inventory(uuid,integer) from public, anon, authenticated;
revoke execute on function public.consume_reserved_inventory(uuid,integer) from public, anon, authenticated;
