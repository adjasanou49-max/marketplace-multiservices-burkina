
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
 v_expected text;
begin
 if not exists (
   select 1 from public.user_roles ur
   where ur.user_id=(select auth.uid()) and ur.role='COURIER'
 ) then
   raise exception 'courier_role_required';
 end if;

 select * into v_assignment
 from public.delivery_assignments
 where package_id=p_package_id
   and courier_id=(select auth.uid())
   and status='ASSIGNED'
 for update;

 if not found then raise exception 'active_assignment_not_found'; end if;

 select * into v_package
 from public.order_packages
 where id=p_package_id
 for update;

 if not found then raise exception 'package_not_found'; end if;
 if v_package.status <> 'READY_FOR_PICKUP' then
   raise exception 'package_not_ready';
 end if;
 if v_package.pickup_code_hash is null then
   raise exception 'pickup_code_missing';
 end if;

 v_expected := encode(digest(p_pickup_code,'sha256'),'hex');
 if v_expected <> v_package.pickup_code_hash then
   raise exception 'invalid_pickup_code';
 end if;

 update public.order_packages
 set status='PICKED_UP', picked_up_at=now(), updated_at=now()
 where id=p_package_id;

 update public.delivery_assignments
 set status='PICKED_UP', accepted_at=coalesce(accepted_at,now())
 where id=v_assignment.id;

 insert into public.delivery_assignment_events
   (assignment_id,actor_id,event_type,metadata)
 values
   (v_assignment.id,(select auth.uid()),'PACKAGE_PICKED_UP',
    jsonb_build_object('package_id',p_package_id));

 return v_assignment.id;
end $$;

revoke execute on function public.confirm_package_pickup(uuid,text) from public,anon,authenticated;
