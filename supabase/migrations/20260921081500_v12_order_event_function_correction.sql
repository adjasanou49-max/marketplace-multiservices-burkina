
drop function if exists public.create_order_event(uuid,public.order_status,text);
create or replace function public.create_order_event(
 p_order_id uuid, p_status public.order_status, p_note text default null
) returns bigint
language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_id bigint;
begin
 if not exists (select 1 from public.orders where id=p_order_id and customer_id=(select auth.uid())) then
  raise exception 'order_not_owned';
 end if;
 insert into public.order_events(order_id,actor_id,status,metadata)
 values(p_order_id,(select auth.uid()),p_status,jsonb_build_object('note',p_note))
 returning id into v_id;
 return v_id;
end $$;
revoke execute on function public.create_order_event(uuid,public.order_status,text) from public,anon,authenticated;
