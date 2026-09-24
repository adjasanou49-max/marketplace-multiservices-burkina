
alter table public.returns add constraint returns_reason_nonempty check(length(trim(reason))>0);
alter table public.disputes add constraint disputes_reason_nonempty check(length(trim(reason))>0);
create index if not exists idx_returns_customer_created on public.returns(customer_id,created_at desc);
create index if not exists idx_returns_order_status on public.returns(order_id,status);
create index if not exists idx_return_events_return_created on public.return_events(return_id,created_at desc);
create index if not exists idx_disputes_order_status on public.disputes(order_id,status);
create index if not exists idx_dispute_messages_dispute_created on public.dispute_messages(dispute_id,created_at desc);
create index if not exists idx_dispute_evidence_dispute_created on public.dispute_evidence(dispute_id,created_at desc);
create index if not exists idx_order_events_order_created on public.order_events(order_id,created_at desc);

create or replace function public.open_return(
 p_order_id uuid,p_order_item_id uuid,p_reason text
) returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if nullif(trim(p_reason),'') is null then raise exception 'reason_required'; end if;
 if not exists(select 1 from public.orders where id=p_order_id and customer_id=v_user) then raise exception 'order_not_owned'; end if;
 if p_order_item_id is not null and not exists(
   select 1 from public.order_items oi join public.order_groups og on og.id=oi.order_group_id
   where oi.id=p_order_item_id and og.order_id=p_order_id
 ) then raise exception 'order_item_invalid'; end if;
 if exists(select 1 from public.returns where order_id=p_order_id and coalesce(order_item_id,'00000000-0000-0000-0000-000000000000')=coalesce(p_order_item_id,'00000000-0000-0000-0000-000000000000') and status not in ('REJECTED','CANCELLED','COMPLETED')) then raise exception 'return_already_open'; end if;
 insert into public.returns(order_id,order_item_id,customer_id,reason,status)
 values(p_order_id,p_order_item_id,v_user,trim(p_reason),'REQUESTED') returning id into v_id;
 insert into public.return_events(return_id,actor_id,event_type,metadata)
 values(v_id,v_user,'REQUESTED',jsonb_build_object('reason',trim(p_reason)));
 return v_id;
end $$;
revoke execute on function public.open_return(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.open_return(uuid,uuid,text) to service_role;
