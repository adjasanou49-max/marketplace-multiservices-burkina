
create or replace function public.admin_add_associate_after_payment(
  p_company_id uuid,
  p_shareholder_id uuid,
  p_share_class_id uuid,
  p_shares numeric,
  p_paid_amount numeric,
  p_payment_reference text
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_holding_id uuid;
  v_nominal numeric;
  v_required numeric;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;

  if p_shares is null or p_shares <= 0 then
    raise exception 'INVALID_SHARES';
  end if;
  if p_paid_amount is null or p_paid_amount <= 0 then
    raise exception 'INVALID_PAYMENT_AMOUNT';
  end if;
  if nullif(trim(p_payment_reference),'') is null then
    raise exception 'PAYMENT_REFERENCE_REQUIRED';
  end if;

  select nominal_value
    into v_nominal
  from public.share_classes
  where id = p_share_class_id
    and company_id = p_company_id;

  if not found then
    raise exception 'SHARE_CLASS_NOT_FOUND';
  end if;

  if not exists(select 1 from public.company where id = p_company_id) then
    raise exception 'COMPANY_NOT_FOUND';
  end if;

  if not exists(select 1 from auth.users where id = p_shareholder_id) then
    raise exception 'SHAREHOLDER_NOT_FOUND';
  end if;

  v_required := v_nominal * p_shares;
  if p_paid_amount < v_required then
    raise exception 'PAYMENT_BELOW_SHARE_VALUE';
  end if;

  if exists (
    select 1
    from public.share_payments sp
    join public.shareholdings sh on sh.id = sp.holding_id
    where sh.company_id = p_company_id
      and sh.shareholder_id = p_shareholder_id
      and sp.payment_reference = trim(p_payment_reference)
      and sp.status = 'PAID'
  ) then
    raise exception 'PAYMENT_REFERENCE_ALREADY_USED';
  end if;

  insert into public.shareholdings(
    company_id,shareholder_id,share_class_id,shares,paid_amount,status
  )
  values(
    p_company_id,p_shareholder_id,p_share_class_id,p_shares,p_paid_amount,'ACTIVE'
  )
  on conflict(company_id,shareholder_id,share_class_id)
  do update set
    shares = public.shareholdings.shares + excluded.shares,
    paid_amount = public.shareholdings.paid_amount + excluded.paid_amount,
    status = 'ACTIVE'
  returning id into v_holding_id;

  insert into public.share_payments(
    holding_id,amount,payment_reference,status,paid_at
  )
  values(
    v_holding_id,p_paid_amount,trim(p_payment_reference),'PAID',now()
  );

  insert into public.company_members(company_id,user_id,role_title,status)
  values(p_company_id,p_shareholder_id,'ASSOCIE','ACTIVE')
  on conflict(company_id,user_id)
  do update set
    role_title='ASSOCIE',
    status='ACTIVE';

  return v_holding_id;
end;
$$;

revoke all on function public.admin_add_associate_after_payment(uuid,uuid,uuid,numeric,numeric,text) from public,anon;
grant execute on function public.admin_add_associate_after_payment(uuid,uuid,uuid,numeric,numeric,text) to authenticated;
