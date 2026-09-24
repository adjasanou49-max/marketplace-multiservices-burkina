
create table if not exists public.package_inventory_consumptions (
  package_id uuid primary key references public.order_packages(id) on delete cascade,
  consumed_at timestamptz not null default now()
);
alter table public.package_inventory_consumptions enable row level security;

create or replace function public.consume_package_inventory(
  p_package_id uuid
) returns integer
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_count integer:=0;
 v_item record;
begin
 if p_package_id is null then raise exception 'package_required'; end if;

 insert into public.package_inventory_consumptions(package_id)
 values(p_package_id)
 on conflict (package_id) do nothing;

 if not found then
   return 0;
 end if;

 for v_item in
   select oi.product_id,oi.quantity
   from public.order_items oi
   join public.order_groups og on og.id=oi.order_group_id
   join public.order_packages op on op.order_group_id=og.id
   where op.id=p_package_id
 loop
   if not public.consume_reserved_inventory(v_item.product_id,v_item.quantity) then
     raise exception 'reserved_inventory_insufficient';
   end if;
   v_count:=v_count+1;
 end loop;
 return v_count;
end;
$$;
revoke all on function public.consume_package_inventory(uuid) from public,anon,authenticated;
grant execute on function public.consume_package_inventory(uuid) to service_role;

create or replace function public.confirm_package_pickup(
 p_package_id uuid,
 p_pickup_code text
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_assignment public.delivery_assignments%rowtype;
 v_package public.order_packages%rowtype;
begin
 if not exists(select 1 from public.user_roles where user_id=(select auth.uid()) and role='COURIER') then
   raise exception 'courier_role_required';
 end if;
 if p_pickup_code is null or length(trim(p_pickup_code)) < 4 then raise exception 'pickup_code_required'; end if;

 select * into v_assignment from public.delivery_assignments
 where package_id=p_package_id and courier_id=(select auth.uid()) and status='ASSIGNED' for update;
 if not found then raise exception 'assignment_not_found'; end if;

 select * into v_package from public.order_packages where id=p_package_id for update;
 if not found then raise exception 'package_not_found'; end if;
 if v_package.status <> 'READY_FOR_PICKUP' then raise exception 'package_not_ready'; end if;
 if v_package.pickup_code_hash is null or encode(digest(trim(p_pickup_code),'sha256'),'hex') <> v_package.pickup_code_hash then
   raise exception 'pickup_code_invalid';
 end if;

 perform public.consume_package_inventory(p_package_id);

 update public.order_packages
 set status='PICKED_UP',picked_up_at=now(),updated_at=now()
 where id=p_package_id;

 update public.delivery_assignments set status='PICKED_UP',accepted_at=coalesce(accepted_at,now())
 where id=v_assignment.id;

 insert into public.delivery_assignment_events(assignment_id,actor_id,event_type,metadata)
 values(v_assignment.id,(select auth.uid()),'PACKAGE_PICKED_UP',jsonb_build_object('package_id',p_package_id));

 return v_assignment.id;
end;
$$;
revoke all on function public.confirm_package_pickup(uuid,text) from public,anon,authenticated;
grant execute on function public.confirm_package_pickup(uuid,text) to service_role;
