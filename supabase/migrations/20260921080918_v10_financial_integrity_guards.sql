
alter table public.payment_events
  add constraint payment_events_event_type_nonempty check(length(trim(event_type))>0);

create unique index if not exists ux_payment_events_idempotency
on public.payment_events(payment_id,event_type,coalesce(provider_reference,''));

alter table public.commissions
  add constraint commissions_rate_valid check(rate>=0 and rate<=100),
  add constraint commissions_amounts_valid check(base_amount>=0 and commission_amount>=0);

alter table public.seller_ledger
  add constraint seller_ledger_amount_nonnegative check(amount>=0);

alter table public.seller_payouts
  add constraint seller_payouts_amount_nonnegative check(amount>=0);

alter table public.refunds
  add constraint refunds_amount_positive check(amount>0);

create index if not exists idx_payment_events_payment_time on public.payment_events(payment_id,created_at desc);
create index if not exists idx_seller_ledger_seller_time on public.seller_ledger(seller_id,created_at desc);
create index if not exists idx_commissions_seller_status on public.commissions(seller_id,status);
