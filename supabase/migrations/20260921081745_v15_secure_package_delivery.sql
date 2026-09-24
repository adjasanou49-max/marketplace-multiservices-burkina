
create or replace function public.confirm_package_delivery(
 p_package_id uuid,
 p_delivery_code text default null
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_assignment public.delivery_assignments%rowtype;
 v_package public.order_packages%rowtype;
 v_order_id uuid;
 v_customer_id uuid;
begin
 if not exists (
   select 1 from public.user_roles ur
   where ur.user_id=(select auth.uid()) and ur.role='COURIER'
 ) then raise exception 'courier_role_required'; end if;

 select * into v_assignment
 from public.delivery_assignments
 where package_id=p_package_id
   and courier_id=(select auth.uid())
   and status in ('PICKED_UP','IN_TRANSIT')
 for update;

 if not found then raise exception 'active_assignment_not_found'; end if;

 select * into v_package
 from public.order_packages
 where id=p_package_id
 for update;

 if not found then raise exception 'package_not_found'; end if;

 select o.id,o.customer_id into v_order_id,v_customer_id
 from public.order_groups og
 join public.orders o on o.id=og.order_id
 where og.id=v_package.order_group_id;

 if v_package.status not in ('PICKED_UP','IN_TRANSIT') then
   raise exception 'package_not_in_delivery';
 end if;

 if p_delivery_code is not null and v_customer_id is null then
   raise exception 'delivery_code_context_invalid';
 end if;

 update public.order_packages
 set status='DELIVERED', delivered_at=now(), updated_at=now()
 where id=p_package_id;

 update public.delivery_assignments
 set status='DELIVERED', completed_at=now()
 where id=v_assignment.id;

 insert into public.delivery_assignment_events
   (assignment_id,actor_id,event_type,metadata)
 values
   (v_assignment.id,(select auth.uid()),'PACKAGE_DELIVERED',
    jsonb_build_object('package_id',p_package_id,'order_id',v_order_id));

 return v_assignment.id;
end $$;

revoke execute on function public.confirm_package_delivery(uuid,text) from public,anon,authenticated;
