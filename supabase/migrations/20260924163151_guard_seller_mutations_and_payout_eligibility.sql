begin;

do $block$
declare
  r record;
  v_def text;
  v_new text;
begin
  for r in
    select p.oid
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    join pg_language l on l.oid=p.prolang
    where n.nspname='public'
      and l.lanname='plpgsql'
      and p.prosecdef
      and has_function_privilege('authenticated',p.oid,'EXECUTE')
      and p.proname in (
        'create_seller_coupon',
        'create_seller_product',
        'create_seller_promotion',
        'create_seller_shop',
        'set_seller_coupon_active',
        'set_seller_promotion_active',
        'set_seller_stock',
        'update_seller_profile',
        'update_seller_shop'
      )
  loop
    v_def := pg_get_functiondef(r.oid);
    if position('private.require_active_account()' in v_def) = 0 then
      v_new := regexp_replace(
        v_def,
        '\bbegin\b',
        E'begin\n  perform private.require_active_account();',
        1,
        1,
        'i'
      );
      if v_new <> v_def then
        execute v_new;
      end if;
    end if;
  end loop;
end;
$block$;

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
  perform private.require_active_account();

  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select s.id
    into v_payout
  from public.sellers s
  where s.id = p_seller_id
    and s.user_id = v_user
    and s.verification_status = 'VERIFIED'::public.verification_status
  for update;

  if v_payout is null then
    raise exception 'seller_not_eligible';
  end if;

  if p_amount is null or p_amount <= 0 then
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

commit;