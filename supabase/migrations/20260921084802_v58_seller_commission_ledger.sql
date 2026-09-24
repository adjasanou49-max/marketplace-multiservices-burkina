
create unique index if not exists uq_commission_order_group
on public.commissions(order_group_id);

create unique index if not exists uq_seller_ledger_ref_type
on public.seller_ledger(seller_id,entry_type,reference_id);

create or replace function public.finalize_seller_group(
  p_order_group_id uuid,
  p_commission_rate numeric default 0
) returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_group public.order_groups%rowtype;
 v_seller_id uuid;
 v_commission numeric;
 v_net numeric;
begin
 if p_commission_rate < 0 or p_commission_rate > 100 then raise exception 'commission_rate_invalid'; end if;

 select * into v_group from public.order_groups where id=p_order_group_id for update;
 if not found then raise exception 'order_group_not_found'; end if;
 if v_group.status <> 'DELIVERED' then raise exception 'group_not_delivered'; end if;

 select s.id into v_seller_id
 from public.shops sh join public.sellers s on s.id=sh.seller_id
 where sh.id=v_group.shop_id;
 if v_seller_id is null then raise exception 'seller_not_found'; end if;

 v_commission := round(v_group.subtotal * p_commission_rate / 100,2);
 v_net := v_group.subtotal - v_commission;

 insert into public.commissions(seller_id,order_group_id,rate,base_amount,commission_amount,currency,status)
 values(v_seller_id,p_order_group_id,p_commission_rate,v_group.subtotal,v_commission,'XOF','POSTED')
 on conflict (order_group_id) do nothing;

 if found then
   insert into public.seller_ledger(seller_id,order_group_id,entry_type,amount,currency,reference_id)
   values(v_seller_id,p_order_group_id,'SALE',v_group.subtotal,'XOF',p_order_group_id);

   if v_commission > 0 then
     insert into public.seller_ledger(seller_id,order_group_id,entry_type,amount,currency,reference_id)
     values(v_seller_id,p_order_group_id,'COMMISSION',-v_commission,'XOF',p_order_group_id);
   end if;
 end if;

 return true;
end;
$$;
revoke all on function public.finalize_seller_group(uuid,numeric) from public,anon,authenticated;
grant execute on function public.finalize_seller_group(uuid,numeric) to service_role;

create or replace function public.request_seller_payout_secure(
 p_seller_id uuid,
 p_amount numeric,
 p_provider text
) returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_balance numeric;
 v_payout uuid;
begin
 if p_amount <= 0 then raise exception 'amount_invalid'; end if;
 if p_provider is null or length(trim(p_provider))=0 then raise exception 'provider_required'; end if;

 select coalesce(sum(amount),0) into v_balance
 from public.seller_ledger
 where seller_id=p_seller_id;

 if p_amount > v_balance then raise exception 'insufficient_seller_balance'; end if;

 insert into public.seller_payouts(seller_id,amount,currency,provider,status)
 values(p_seller_id,p_amount,'XOF',trim(p_provider),'PENDING')
 returning id into v_payout;

 insert into public.seller_ledger(seller_id,entry_type,amount,currency,reference_id)
 values(p_seller_id,'PAYOUT',-p_amount,'XOF',v_payout);

 return v_payout;
end;
$$;
revoke all on function public.request_seller_payout_secure(uuid,numeric,text) from public,anon,authenticated;
grant execute on function public.request_seller_payout_secure(uuid,numeric,text) to service_role;
