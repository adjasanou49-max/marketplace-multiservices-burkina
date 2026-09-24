
create or replace function public.transition_order_group_status(
 p_order_group_id uuid,
 p_next_status public.order_status,
 p_note text default null
) returns public.order_status
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_group public.order_groups%rowtype;
 v_shop_owner uuid;
 v_current public.order_status;
begin
 select * into v_group from public.order_groups where id=p_order_group_id for update;
 if not found then raise exception 'order_group_not_found'; end if;
 v_current := v_group.status;

 select s.user_id into v_shop_owner
 from public.shops sh join public.sellers s on s.id=sh.seller_id
 where sh.id=v_group.shop_id;

 if not (
   exists(select 1 from public.admin_users au where au.user_id=(select auth.uid()) and au.active=true)
   or v_shop_owner=(select auth.uid())
 ) then raise exception 'not_authorized'; end if;

 if p_next_status='CONFIRMED' and v_current<>'PAID' then raise exception 'invalid_group_transition'; end if;
 if p_next_status='PREPARING' and v_current<>'CONFIRMED' then raise exception 'invalid_group_transition'; end if;
 if p_next_status='READY_FOR_PICKUP' and v_current<>'PREPARING' then raise exception 'invalid_group_transition'; end if;
 if p_next_status='CANCELLED' and v_current not in ('PAID','CONFIRMED','PREPARING') then raise exception 'invalid_group_transition'; end if;
 if p_next_status not in ('CONFIRMED','PREPARING','READY_FOR_PICKUP','CANCELLED') then raise exception 'unsupported_seller_transition'; end if;

 update public.order_groups set status=p_next_status where id=p_order_group_id;

 insert into public.order_events(order_id,actor_id,status,metadata)
 values(v_group.order_id,(select auth.uid()),p_next_status,
   jsonb_build_object('scope','order_group','order_group_id',p_order_group_id,'note',p_note));

 if p_next_status='CANCELLED' then
   update public.orders
   set status='CANCELLED', updated_at=now()
   where id=v_group.order_id
   and not exists(select 1 from public.order_groups og where og.order_id=v_group.order_id and og.status not in ('CANCELLED','DELIVERED'));
 end if;

 return p_next_status;
end;
$$;
revoke all on function public.transition_order_group_status(uuid,public.order_status,text) from public,anon,authenticated;
grant execute on function public.transition_order_group_status(uuid,public.order_status,text) to service_role;

create or replace function public.sync_parent_order_status(p_order_id uuid)
returns public.order_status
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_status public.order_status;
 v_total int;
 v_paid int;
 v_confirmed int;
 v_preparing int;
 v_ready int;
 v_transit int;
 v_delivered int;
begin
 select count(*) into v_total from public.order_groups where order_id=p_order_id;
 if v_total=0 then return null; end if;
 select count(*) into v_paid from public.order_groups where order_id=p_order_id and status='PAID';
 select count(*) into v_confirmed from public.order_groups where order_id=p_order_id and status='CONFIRMED';
 select count(*) into v_preparing from public.order_groups where order_id=p_order_id and status='PREPARING';
 select count(*) into v_ready from public.order_groups where order_id=p_order_id and status='READY_FOR_PICKUP';
 select count(*) into v_transit from public.order_groups where order_id=p_order_id and status in ('IN_TRANSIT','DELIVERED');
 select count(*) into v_delivered from public.order_groups where order_id=p_order_id and status='DELIVERED';

 if v_delivered=v_total then v_status='DELIVERED';
 elsif v_transit>0 then v_status='IN_TRANSIT';
 elsif v_ready=v_total then v_status='READY_FOR_PICKUP';
 elsif v_ready>0 or v_preparing>0 then v_status='PREPARING';
 elsif v_confirmed>0 then v_status='CONFIRMED';
 elsif v_paid=v_total then v_status='PAID';
 else
   v_status='PAID';
 end if;

 update public.orders set status=v_status,updated_at=now() where id=p_order_id;
 return v_status;
end;
$$;
revoke all on function public.sync_parent_order_status(uuid) from public,anon,authenticated;
grant execute on function public.sync_parent_order_status(uuid) to service_role;
