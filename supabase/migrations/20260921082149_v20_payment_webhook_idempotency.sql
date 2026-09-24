
create or replace function public.process_payment_provider_event(
  p_payment_id uuid,
  p_event_type text,
  p_provider_reference text default null,
  p_payload jsonb default '{}'::jsonb
) returns boolean
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_payment public.payments%rowtype;
  v_event_id uuid;
  v_order_id uuid;
begin
  if nullif(trim(p_event_type),'') is null then raise exception 'invalid_event_type'; end if;

  select * into v_payment
  from public.payments
  where id=p_payment_id
  for update;

  if not found then raise exception 'payment_not_found'; end if;

  insert into public.payment_events(payment_id,event_type,provider_reference,payload)
  values(p_payment_id,trim(p_event_type),p_provider_reference,coalesce(p_payload,'{}'::jsonb))
  on conflict do nothing
  returning id into v_event_id;

  if v_event_id is null then
    return false;
  end if;

  v_order_id := v_payment.order_id;

  if upper(p_event_type) in ('SUCCEEDED','SUCCESS','PAID','COMPLETED') then
    if v_payment.amount <= 0 or v_payment.currency <> 'XOF' then raise exception 'invalid_payment'; end if;

    update public.payments
      set status='SUCCEEDED',
          provider_reference=coalesce(p_provider_reference,provider_reference),
          updated_at=now()
      where id=p_payment_id;

    update public.orders
      set status='PAID', updated_at=now()
      where id=v_order_id and status='PENDING_PAYMENT';

    update public.order_groups
      set status='PAID'
      where order_id=v_order_id and status='PENDING_PAYMENT';

  elsif upper(p_event_type) in ('FAILED','FAILURE') then
    update public.payments
      set status='FAILED',
          provider_reference=coalesce(p_provider_reference,provider_reference),
          updated_at=now()
      where id=p_payment_id;

  elsif upper(p_event_type) in ('CANCELLED','CANCELED') then
    update public.payments
      set status='CANCELLED',
          provider_reference=coalesce(p_provider_reference,provider_reference),
          updated_at=now()
      where id=p_payment_id;
  end if;

  return true;
end
$$;

revoke execute on function public.process_payment_provider_event(uuid,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.process_payment_provider_event(uuid,text,text,jsonb) to service_role;
