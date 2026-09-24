
create unique index if not exists uq_commission_order_group
on public.commissions(order_group_id) where order_group_id is not null;

create unique index if not exists uq_seller_ledger_order_sale
on public.seller_ledger(seller_id,order_group_id,entry_type)
where order_group_id is not null and entry_type='SALE';

create or replace function public.finalize_seller_group_financials(p_order_group_id uuid)
returns boolean language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare
 v_group public.order_groups%rowtype;
 v_seller uuid;
 v_rate numeric;
 v_comm numeric;
 v_net numeric;
begin
 select og.id,og.order_id,og.shop_id,og.status,og.subtotal,og.created_at,s.seller_id
 into v_group.id,v_group.order_id,v_group.shop_id,v_group.status,v_group.subtotal,v_group.created_at,v_seller
 from public.order_groups og join public.shops s on s.id=og.shop_id
 where og.id=p_order_group_id for update;
 if not found then raise exception 'order_group_not_found'; end if;
 if v_group.status <> 'DELIVERED' then raise exception 'group_not_delivered'; end if;
 if exists(select 1 from public.commissions where order_group_id=p_order_group_id) then return false; end if;

 select coalesce((value->>'rate')::numeric,0) into v_rate
 from public.platform_settings where key='default_commission_rate' limit 1;
 v_rate:=coalesce(v_rate,0);
 if v_rate<0 or v_rate>100 then raise exception 'invalid_commission_rate'; end if;

 v_comm:=round(v_group.subtotal*v_rate/100,2);
 v_net:=v_group.subtotal-v_comm;

 insert into public.commissions(seller_id,order_group_id,rate,base_amount,commission_amount,currency,status)
 values(v_seller,p_order_group_id,v_rate,v_group.subtotal,v_comm,'XOF','PENDING');

 insert into public.seller_ledger(seller_id,order_group_id,entry_type,amount,currency,reference_id)
 values(v_seller,p_order_group_id,'SALE',v_net,'XOF',p_order_group_id);
 return true;
end $$;

revoke execute on function public.finalize_seller_group_financials(uuid) from public,anon,authenticated;
grant execute on function public.finalize_seller_group_financials(uuid) to service_role;

alter table public.seller_ledger add constraint seller_ledger_amount_nonzero check (amount <> 0);
alter table public.commissions add constraint commissions_rate_range check (rate between 0 and 100);
create index if not exists idx_seller_ledger_seller_created on public.seller_ledger(seller_id,created_at desc);
create index if not exists idx_seller_payouts_seller_status on public.seller_payouts(seller_id,status);
