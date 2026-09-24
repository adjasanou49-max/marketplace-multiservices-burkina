
create index if not exists idx_delivery_assignments_package_status
on public.delivery_assignments(package_id,status);

create or replace function public.assign_package_to_courier(
 p_package_id uuid,
 p_courier_id uuid
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 if not exists(select 1 from public.delivery_drivers where id=p_courier_id) then
   raise exception 'courier_not_found';
 end if;
 if exists(select 1 from public.delivery_assignments where package_id=p_package_id and status not in ('CANCELLED','COMPLETED')) then
   raise exception 'package_already_assigned';
 end if;
 update public.order_packages set status='READY_FOR_PICKUP',updated_at=now()
 where id=p_package_id and status='CREATED';
 if not found then raise exception 'package_not_ready_for_assignment'; end if;

 insert into public.delivery_assignments(package_id,courier_id,status,assigned_at)
 values(p_package_id,p_courier_id,'ASSIGNED',now()) returning id into v_id;
 return v_id;
end;
$$;
revoke all on function public.assign_package_to_courier(uuid,uuid) from public,anon,authenticated;
grant execute on function public.assign_package_to_courier(uuid,uuid) to service_role;

create or replace function public.accept_delivery_assignment(p_assignment_id uuid)
returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 update public.delivery_assignments
 set status='ACCEPTED',accepted_at=now()
 where id=p_assignment_id
 and courier_id=(select auth.uid())
 and status='ASSIGNED'
 returning id into v_id;
 if v_id is null then raise exception 'assignment_not_available'; end if;
 return v_id;
end;
$$;
revoke all on function public.accept_delivery_assignment(uuid) from public,anon,authenticated;
grant execute on function public.accept_delivery_assignment(uuid) to service_role;

create or replace function public.start_package_delivery(p_package_id uuid)
returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 update public.order_packages p
 set status='IN_TRANSIT',updated_at=now()
 where p.id=p_package_id
 and p.status='PICKED_UP'
 and exists(
   select 1 from public.delivery_assignments da
   where da.package_id=p.id and da.courier_id=(select auth.uid()) and da.status='PICKED_UP'
 )
 returning p.id into v_id;
 if v_id is null then raise exception 'package_not_in_courier_possession'; end if;

 update public.delivery_assignments set status='IN_TRANSIT'
 where package_id=p_package_id and courier_id=(select auth.uid()) and status='PICKED_UP';
 return v_id;
end;
$$;
revoke all on function public.start_package_delivery(uuid) from public,anon,authenticated;
grant execute on function public.start_package_delivery(uuid) to service_role;
