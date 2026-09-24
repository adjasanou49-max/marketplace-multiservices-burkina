
create or replace function public.sync_order_after_package_change()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_order_id uuid;
 v_total integer;
 v_delivered integer;
 v_in_transit integer;
begin
 select og.order_id into v_order_id
 from public.order_groups og
 where og.id=new.order_group_id;

 select count(*)::int,
        count(*) filter (where op.status='DELIVERED')::int,
        count(*) filter (where op.status in ('PICKED_UP','IN_TRANSIT'))::int
 into v_total,v_delivered,v_in_transit
 from public.order_packages op
 where op.order_group_id=new.order_group_id;

 if v_total > 0 and v_delivered = v_total then
   update public.order_groups
   set status='DELIVERED'
   where id=new.order_group_id
     and status <> 'DELIVERED';
 elsif v_in_transit > 0 then
   update public.order_groups
   set status='IN_TRANSIT'
   where id=new.order_group_id
     and status not in ('DELIVERED','CANCELLED');
 end if;

 select count(*)::int,
        count(*) filter (where og.status='DELIVERED')::int
 into v_total,v_delivered
 from public.order_groups og
 where og.order_id=v_order_id;

 if v_total > 0 and v_delivered=v_total then
   update public.orders
   set status='DELIVERED',updated_at=now()
   where id=v_order_id and status not in ('CANCELLED','REFUNDED','DISPUTED');
 elsif exists (
   select 1 from public.order_groups og
   where og.order_id=v_order_id and og.status='IN_TRANSIT'
 ) then
   update public.orders
   set status='IN_TRANSIT',updated_at=now()
   where id=v_order_id and status not in ('DELIVERED','CANCELLED','REFUNDED','DISPUTED');
 end if;

 return new;
end $$;

drop trigger if exists trg_sync_order_after_package_change on public.order_packages;
create trigger trg_sync_order_after_package_change
after update of status on public.order_packages
for each row execute function public.sync_order_after_package_change();

revoke execute on function public.sync_order_after_package_change() from public,anon,authenticated;
