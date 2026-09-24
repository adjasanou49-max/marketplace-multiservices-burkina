
alter table public.commissions
  drop constraint if exists commissions_status_check;
alter table public.commissions
  add constraint commissions_status_check
  check (status in ('PENDING','POSTED','REVERSED','CANCELLED'));

create unique index if not exists uq_seller_payout_provider_ref
on public.seller_payouts(provider_reference)
where provider_reference is not null;

create or replace function public.reverse_seller_group(
 p_order_group_id uuid,
 p_reason text default null
) returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_comm public.commissions%rowtype;
 v_seller uuid;
begin
 select * into v_comm from public.commissions where order_group_id=p_order_group_id for update;
 if not found then return false; end if;
 if v_comm.status='REVERSED' then return true; end if;

 select seller_id into v_seller from public.commissions where id=v_comm.id;
 update public.commissions set status='REVERSED' where id=v_comm.id;

 insert into public.seller_ledger(seller_id,order_group_id,entry_type,amount,currency,reference_id)
 values(v_seller,p_order_group_id,'COMMISSION_REVERSAL',v_comm.commission_amount,'XOF',v_comm.id);

 insert into public.seller_ledger(seller_id,order_group_id,entry_type,amount,currency,reference_id)
 values(v_seller,p_order_group_id,'SALE_REVERSAL',-v_comm.base_amount,'XOF',v_comm.id);

 return true;
end;
$$;
revoke all on function public.reverse_seller_group(uuid,text) from public,anon,authenticated;
grant execute on function public.reverse_seller_group(uuid,text) to service_role;
