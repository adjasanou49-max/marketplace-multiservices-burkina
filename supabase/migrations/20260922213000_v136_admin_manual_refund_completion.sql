create or replace function public.admin_complete_manual_refund(
  p_refund_id uuid,
  p_provider_reference text
)
returns boolean
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_provider text;
  v_status text;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;

  if nullif(trim(p_provider_reference),'') is null then
    raise exception 'provider_reference_required';
  end if;

  select p.provider, r.status
  into v_provider, v_status
  from public.refunds r
  join public.payments p on p.id=r.payment_id
  where r.id=p_refund_id;

  if not found then
    raise exception 'refund_not_found';
  end if;

  if v_provider <> 'CINETPAY' then
    raise exception 'manual_completion_not_for_provider';
  end if;

  if v_status not in ('APPROVED','PROCESSING','FAILED') then
    raise exception 'refund_not_completable';
  end if;

  perform public.complete_refund(
    p_refund_id,
    trim(p_provider_reference)
  );

  return true;
end;
$function$;

revoke all on function public.admin_complete_manual_refund(uuid,text) from public;
revoke all on function public.admin_complete_manual_refund(uuid,text) from anon;
grant execute on function public.admin_complete_manual_refund(uuid,text) to authenticated;
