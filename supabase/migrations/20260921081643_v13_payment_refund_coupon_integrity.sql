
alter table public.payments
  add constraint payments_amount_positive check (amount > 0),
  add constraint payments_currency_xof check (currency = 'XOF');

alter table public.refunds
  add constraint refunds_currency_xof check (currency = 'XOF'),
  add constraint refunds_status_valid check (status in ('PENDING','PROCESSING','COMPLETED','FAILED','CANCELLED'));

alter table public.seller_payouts
  add constraint seller_payouts_currency_xof check (currency = 'XOF'),
  add constraint seller_payouts_amount_positive check (amount > 0);

alter table public.coupon_usage
  add constraint coupon_usage_unique_order unique (coupon_id, order_id);

create unique index if not exists ux_coupon_usage_user_coupon
on public.coupon_usage(coupon_id,user_id);

create or replace function public.validate_refund_amount()
returns trigger
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_paid numeric; v_refunded numeric;
begin
 select coalesce(sum(p.amount),0) into v_paid
 from public.payments p
 where p.order_id=new.order_id and p.status='SUCCEEDED';

 select coalesce(sum(r.amount),0) into v_refunded
 from public.refunds r
 where r.order_id=new.order_id
   and r.status in ('PENDING','PROCESSING','COMPLETED')
   and r.id <> coalesce(new.id,'00000000-0000-0000-0000-000000000000');

 if new.amount <= 0 or new.amount + v_refunded > v_paid then
   raise exception 'refund_amount_exceeds_paid_amount';
 end if;
 return new;
end $$;

drop trigger if exists trg_validate_refund_amount on public.refunds;
create trigger trg_validate_refund_amount
before insert or update of amount,status,order_id on public.refunds
for each row execute function public.validate_refund_amount();

revoke execute on function public.validate_refund_amount() from public,anon,authenticated;
