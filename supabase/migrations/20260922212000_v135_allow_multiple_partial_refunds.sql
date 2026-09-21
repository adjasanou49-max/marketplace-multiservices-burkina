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
    and p.status in ('SUCCEEDED','PARTIALLY_REFUNDED','REFUNDED');

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
