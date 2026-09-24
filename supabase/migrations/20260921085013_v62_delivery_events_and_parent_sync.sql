
create or replace function public.log_delivery_event(
 p_package_id uuid,
 p_status public.delivery_status,
 p_metadata jsonb default '{}'::jsonb
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 insert into public.delivery_events(package_id,actor_id,status,metadata)
 values(p_package_id,(select auth.uid()),p_status,coalesce(p_metadata,'{}'::jsonb))
 returning id into v_id;
 return v_id;
end;
$$;
revoke all on function public.log_delivery_event(uuid,public.delivery_status,jsonb) from public,anon,authenticated;
grant execute on function public.log_delivery_event(uuid,public.delivery_status,jsonb) to service_role;

create or replace function public.sync_after_package_delivery(p_package_id uuid)
returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_group uuid; v_order uuid; v_status public.order_status;
begin
 select op.order_group_id,og.order_id into v_group,v_order
 from public.order_packages op join public.order_groups og on og.id=op.order_group_id
 where op.id=p_package_id;
 if v_group is null then raise exception 'package_not_found'; end if;

 update public.delivery_assignments
 set status='COMPLETED',completed_at=now()
 where package_id=p_package_id and status in ('IN_TRANSIT','PICKED_UP','ACCEPTED');

 select public.sync_parent_order_status(v_order) into v_status;
 return true;
end;
$$;
revoke all on function public.sync_after_package_delivery(uuid) from public,anon,authenticated;
grant execute on function public.sync_after_package_delivery(uuid) to service_role;

create or replace function public.confirm_package_delivery(
 p_package_id uuid,
 p_delivery_code text
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 if p_delivery_code is null or p_delivery_code !~ '^[0-9]{6}$' then raise exception 'delivery_code_invalid'; end if;

 update public.order_packages p
 set status='DELIVERED',delivered_at=now(),updated_at=now()
 where p.id=p_package_id
 and p.status='IN_TRANSIT'
 and p.delivery_code_hash=encode(digest(p_delivery_code,'sha256'),'hex')
 and exists(
   select 1 from public.delivery_assignments da
   where da.package_id=p.id and da.courier_id=(select auth.uid()) and da.status='IN_TRANSIT'
 )
 returning p.id into v_id;

 if v_id is null then raise exception 'delivery_not_authorized_or_code_invalid'; end if;

 insert into public.delivery_events(package_id,actor_id,status,metadata)
 values(p_package_id,(select auth.uid()),'DELIVERED','{}'::jsonb);

 perform public.sync_after_package_delivery(p_package_id);
 return v_id;
end;
$$;
revoke all on function public.confirm_package_delivery(uuid,text) from public,anon,authenticated;
grant execute on function public.confirm_package_delivery(uuid,text) to service_role;
