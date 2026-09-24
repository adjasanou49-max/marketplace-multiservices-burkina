
alter table public.order_packages
  add column if not exists delivery_code_hash text;

create or replace function public.set_order_delivery_code(
  p_order_id uuid,
  p_delivery_code text
) returns integer
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_count integer;
begin
  if p_order_id is null or p_delivery_code !~ '^[0-9]{6}$' then raise exception 'delivery_code_invalid'; end if;
  update public.order_packages op
  set delivery_code_hash=encode(digest(p_delivery_code,'sha256'),'hex'), updated_at=now()
  from public.order_groups og
  where op.order_group_id=og.id and og.order_id=p_order_id and op.status='CREATED';
  get diagnostics v_count=row_count;
  if v_count=0 then raise exception 'no_packages_available'; end if;
  return v_count;
end;
$$;
revoke all on function public.set_order_delivery_code(uuid,text) from public,anon,authenticated;
grant execute on function public.set_order_delivery_code(uuid,text) to service_role;

drop function if exists public.confirm_package_delivery(uuid,text);

create function public.confirm_package_delivery(
  p_package_id uuid,
  p_delivery_code text
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_assignment public.delivery_assignments%rowtype;
 v_package public.order_packages%rowtype;
 v_order_id uuid;
begin
 if not exists (select 1 from public.user_roles ur where ur.user_id=(select auth.uid()) and ur.role='COURIER') then
   raise exception 'courier_role_required';
 end if;
 if p_delivery_code is null or p_delivery_code !~ '^[0-9]{6}$' then raise exception 'delivery_code_required'; end if;

 select * into v_assignment
 from public.delivery_assignments
 where package_id=p_package_id and courier_id=(select auth.uid())
   and status in ('PICKED_UP','IN_TRANSIT') for update;
 if not found then raise exception 'active_assignment_not_found'; end if;

 select * into v_package from public.order_packages where id=p_package_id for update;
 if not found then raise exception 'package_not_found'; end if;
 if v_package.status not in ('PICKED_UP','IN_TRANSIT') then raise exception 'package_not_in_delivery'; end if;
 if v_package.delivery_code_hash is null then raise exception 'delivery_code_not_initialized'; end if;
 if encode(digest(p_delivery_code,'sha256'),'hex') <> v_package.delivery_code_hash then raise exception 'delivery_code_invalid'; end if;

 select og.order_id into v_order_id from public.order_groups og where og.id=v_package.order_group_id;

 update public.order_packages set status='DELIVERED',delivered_at=now(),updated_at=now() where id=p_package_id;
 update public.delivery_assignments set status='DELIVERED',completed_at=now() where id=v_assignment.id;
 insert into public.delivery_assignment_events(assignment_id,actor_id,event_type,metadata)
 values(v_assignment.id,(select auth.uid()),'PACKAGE_DELIVERED',
        jsonb_build_object('package_id',p_package_id,'order_id',v_order_id));
 return v_assignment.id;
end;
$$;
revoke all on function public.confirm_package_delivery(uuid,text) from public,anon,authenticated;
grant execute on function public.confirm_package_delivery(uuid,text) to service_role;
