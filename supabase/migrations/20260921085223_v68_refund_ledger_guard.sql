
create or replace function public.complete_refund(
 p_refund_id uuid,
 p_provider_reference text
) returns boolean
language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v public.refunds%rowtype; v_group uuid; v_seller uuid;
begin
 select * into v from public.refunds where id=p_refund_id for update;
 if not found then raise exception 'refund_not_found'; end if;
 if v.status='COMPLETED' then return true; end if;
 if p_provider_reference is null or length(trim(p_provider_reference))=0 then raise exception 'provider_reference_required'; end if;

 update public.refunds set status='COMPLETED',provider_reference=trim(p_provider_reference),completed_at=now()
 where id=p_refund_id;

 select oi.order_group_id into v_group
 from public.order_items oi
 where oi.order_group_id in (select og.id from public.order_groups og join public.orders o on o.id=og.order_id where o.id=v.order_id)
 limit 1;

 if v_group is not null then
   select s.id into v_seller from public.order_groups og join public.shops sh on sh.id=og.shop_id join public.sellers s on s.id=sh.seller_id where og.id=v_group;
   if v_seller is not null then
     insert into public.seller_ledger(seller_id,order_group_id,entry_type,amount,currency,reference_id)
     values(v_seller,v_group,'REFUND',-v.amount,'XOF',v.id);
   end if;
 end if;
 return true;
end; $$;
revoke all on function public.complete_refund(uuid,text) from public,anon,authenticated;
grant execute on function public.complete_refund(uuid,text) to service_role;

create unique index if not exists uq_refund_provider_reference
on public.refunds(provider_reference) where provider_reference is not null;
