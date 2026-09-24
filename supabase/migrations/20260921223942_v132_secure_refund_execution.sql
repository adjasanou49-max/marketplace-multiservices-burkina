alter table public.refunds
  drop constraint if exists refunds_status_valid;

alter table public.refunds
  add constraint refunds_status_valid
  check (status in ('REQUESTED','APPROVED','PROCESSING','COMPLETED','REJECTED','PENDING','FAILED','CANCELLED'));

create or replace function public.validate_refund_amount()
returns trigger
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_paid numeric;
  v_reserved numeric;
begin
  select coalesce(sum(p.amount),0) into v_paid
  from public.payments p
  where p.order_id = new.order_id
    and p.status = 'SUCCEEDED';

  select coalesce(sum(r.amount),0) into v_reserved
  from public.refunds r
  where r.order_id = new.order_id
    and r.status in ('REQUESTED','APPROVED','PENDING','PROCESSING','COMPLETED')
    and r.id <> coalesce(new.id,'00000000-0000-0000-0000-000000000000');

  if new.amount <= 0 or new.amount + v_reserved > v_paid then
    raise exception 'refund_amount_exceeds_paid_amount';
  end if;

  return new;
end;
$function$;

create or replace function public.admin_begin_refund(p_refund_id uuid)
returns table (
  refund_id uuid,
  payment_id uuid,
  order_id uuid,
  amount numeric,
  currency text,
  provider text,
  provider_reference text,
  status text
)
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
begin
  if not private.is_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;

  update public.refunds r
  set status='PROCESSING'
  where r.id=p_refund_id
    and r.status in ('REQUESTED','APPROVED','FAILED','PROCESSING');

  if not found then
    raise exception 'refund_not_requestable';
  end if;

  return query
  select
    r.id,
    r.payment_id,
    r.order_id,
    r.amount,
    r.currency,
    p.provider,
    p.provider_reference,
    r.status
  from public.refunds r
  join public.payments p on p.id=r.payment_id
  where r.id=p_refund_id;
end;
$function$;

revoke all on function public.admin_begin_refund(uuid) from public;
revoke all on function public.admin_begin_refund(uuid) from anon;
grant execute on function public.admin_begin_refund(uuid) to authenticated;
