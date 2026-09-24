begin;

alter table public.seller_ledger
  drop constraint if exists seller_ledger_entry_type_check;
alter table public.seller_ledger
  add constraint seller_ledger_entry_type_check
  check (entry_type = any (array[
    'SALE'::text,'COMMISSION'::text,'REFUND'::text,'PAYOUT'::text,
    'ADJUSTMENT'::text,'COMMISSION_REVERSAL'::text,'SALE_REVERSAL'::text,'PAYOUT_REVERSAL'::text
  ]));

alter table public.seller_payouts
  drop constraint if exists seller_payouts_status_check;
alter table public.seller_payouts
  add constraint seller_payouts_status_check
  check (status in ('PENDING','PAID','FAILED'));

create unique index if not exists uq_seller_payouts_provider_reference
on public.seller_payouts(provider_reference)
where provider_reference is not null;

create or replace function public.admin_mark_seller_payout_paid(
  p_payout_id uuid, p_provider_reference text
)
returns boolean
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare v_payout public.seller_payouts%rowtype;
begin
  if not public.is_admin_actor() then raise exception 'admin_access_required' using errcode='42501'; end if;
  if p_payout_id is null or nullif(trim(p_provider_reference),'') is null then raise exception 'payout_reference_required'; end if;
  if length(trim(p_provider_reference)) > 200 then raise exception 'payout_reference_too_long'; end if;
  select * into v_payout from public.seller_payouts where id=p_payout_id for update;
  if not found then raise exception 'payout_not_found'; end if;
  if v_payout.status='PAID' then return true; end if;
  if v_payout.status<>'PENDING' then raise exception 'payout_not_pending'; end if;
  update public.seller_payouts
  set status='PAID',provider_reference=trim(p_provider_reference),paid_at=now()
  where id=p_payout_id;
  insert into public.admin_change_log(actor_id,entity_type,entity_id,action,after_data)
  values(auth.uid(),'seller_payout',p_payout_id,'PAID',
    jsonb_build_object('provider_reference',trim(p_provider_reference),'amount',v_payout.amount,'currency',v_payout.currency));
  return true;
end;
$function$;

create or replace function public.admin_mark_seller_payout_failed(
  p_payout_id uuid, p_reason text
)
returns boolean
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare v_payout public.seller_payouts%rowtype;
begin
  if not public.is_admin_actor() then raise exception 'admin_access_required' using errcode='42501'; end if;
  select * into v_payout from public.seller_payouts where id=p_payout_id for update;
  if not found then raise exception 'payout_not_found'; end if;
  if v_payout.status='FAILED' then return true; end if;
  if v_payout.status<>'PENDING' then raise exception 'payout_not_pending'; end if;
  update public.seller_payouts set status='FAILED' where id=p_payout_id;
  insert into public.seller_ledger(seller_id,entry_type,amount,currency,reference_id)
  values(v_payout.seller_id,'PAYOUT_REVERSAL',v_payout.amount,'XOF',p_payout_id);
  insert into public.admin_change_log(actor_id,entity_type,entity_id,action,after_data)
  values(auth.uid(),'seller_payout',p_payout_id,'FAILED',
    jsonb_build_object('reason',left(coalesce(p_reason,''),500),'amount',v_payout.amount,'currency',v_payout.currency));
  return true;
end;
$function$;

commit;