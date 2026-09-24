
alter table public.inventory
  add constraint inventory_quantity_nonnegative check (quantity >= 0),
  add constraint inventory_reserved_nonnegative check (reserved_quantity >= 0),
  add constraint inventory_reserved_not_above_quantity check (reserved_quantity <= quantity);

create or replace function public.create_order_event(
  p_order_id uuid, p_status public.order_status, p_note text default null
) returns uuid
language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 if not exists (
   select 1 from public.orders
   where id=p_order_id and customer_id=(select auth.uid())
 ) then
   raise exception 'order_not_owned';
 end if;
 insert into public.order_events(order_id,status,note,created_by)
 values(p_order_id,p_status,p_note,(select auth.uid()))
 returning id into v_id;
 return v_id;
end $$;

revoke execute on function public.create_order_event(uuid,public.order_status,text) from public,anon,authenticated;
