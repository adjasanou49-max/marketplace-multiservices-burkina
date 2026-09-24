
create or replace function public.request_seller_payout_secure(
  p_seller_id uuid,
  p_amount numeric,
  p_provider text
)
returns uuid
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_user uuid := auth.uid();
  v_balance numeric;
  v_payout uuid;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select s.id
    into v_payout
  from public.sellers s
  where s.id = p_seller_id
    and s.user_id = v_user
  for update;

  if v_payout is null then
    raise exception 'seller_not_owned';
  end if;

  if p_amount <= 0 then
    raise exception 'amount_invalid';
  end if;

  if p_provider is null
     or upper(trim(p_provider)) not in ('ORANGE_MONEY','WAVE','MOOV_MONEY') then
    raise exception 'provider_invalid';
  end if;

  select coalesce(sum(amount), 0)
    into v_balance
  from public.seller_ledger
  where seller_id = p_seller_id;

  if p_amount > v_balance then
    raise exception 'insufficient_seller_balance';
  end if;

  insert into public.seller_payouts(
    seller_id, amount, currency, provider, status
  )
  values(
    p_seller_id,
    p_amount,
    'XOF',
    upper(trim(p_provider)),
    'PENDING'
  )
  returning id into v_payout;

  insert into public.seller_ledger(
    seller_id, entry_type, amount, currency, reference_id
  )
  values(
    p_seller_id,
    'PAYOUT',
    -p_amount,
    'XOF',
    v_payout
  );

  return v_payout;
end;
$function$;
