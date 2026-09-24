
create or replace function public.validate_order_totals()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
 if new.subtotal < 0 or new.delivery_fee < 0 or new.discount_total < 0 or new.total < 0 then
   raise exception 'negative_order_amount';
 end if;
 if new.total <> new.subtotal + new.delivery_fee - new.discount_total then
   raise exception 'order_total_mismatch';
 end if;
 return new;
end;
$$;
drop trigger if exists trg_validate_order_totals on public.orders;
create trigger trg_validate_order_totals
before insert or update of subtotal,delivery_fee,discount_total,total on public.orders
for each row execute function public.validate_order_totals();
revoke execute on function public.validate_order_totals() from anon,authenticated;
