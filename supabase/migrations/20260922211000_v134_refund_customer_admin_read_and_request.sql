grant execute on function public.request_refund(uuid,numeric,text) to authenticated;

create or replace function public.get_customer_refunds(p_order_id uuid)
returns table (
  refund_id uuid,
  amount numeric,
  currency text,
  reason text,
  status text,
  provider_reference text,
  created_at timestamptz,
  completed_at timestamptz
)
language sql
security definer
set search_path to pg_catalog, public
as $function$
  select r.id,r.amount,r.currency,r.reason,r.status,r.provider_reference,r.created_at,r.completed_at
  from public.refunds r
  join public.orders o on o.id=r.order_id
  where r.order_id=p_order_id and o.customer_id=(select auth.uid())
  order by r.created_at desc;
$function$;

revoke all on function public.get_customer_refunds(uuid) from public;
revoke all on function public.get_customer_refunds(uuid) from anon;
grant execute on function public.get_customer_refunds(uuid) to authenticated;

create or replace function public.get_admin_refunds()
returns table (
  refund_id uuid, order_id uuid, payment_id uuid, customer_id uuid, customer_name text,
  amount numeric, currency text, reason text, refund_status text, provider text,
  provider_reference text, created_at timestamptz, completed_at timestamptz
)
language sql
security definer
set search_path to pg_catalog, public
as $function$
  select r.id,o.id,r.payment_id,o.customer_id,coalesce(pr.display_name,'Client'),
         r.amount,r.currency,r.reason,r.status,p.provider,p.provider_reference,r.created_at,r.completed_at
  from public.refunds r
  join public.orders o on o.id=r.order_id
  join public.payments p on p.id=r.payment_id
  left join public.profiles pr on pr.id=o.customer_id
  where private.is_admin()
  order by r.created_at desc limit 200;
$function$;

revoke all on function public.get_admin_refunds() from public;
revoke all on function public.get_admin_refunds() from anon;
grant execute on function public.get_admin_refunds() to authenticated;

create or replace function public.admin_reject_refund(p_refund_id uuid,p_reason text default null)
returns boolean language plpgsql security definer set search_path to pg_catalog, public as $function$
begin
  if not private.is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  update public.refunds
  set status='REJECTED', reason=case when nullif(trim(p_reason),'') is null then reason
    else coalesce(reason,'') || case when coalesce(reason,'')='' then '' else ' | ' end || 'Admin: ' || trim(p_reason) end
  where id=p_refund_id and status in ('REQUESTED','APPROVED');
  if not found then raise exception 'refund_not_rejectable'; end if;
  return true;
end; $function$;

revoke all on function public.admin_reject_refund(uuid,text) from public;
revoke all on function public.admin_reject_refund(uuid,text) from anon;
grant execute on function public.admin_reject_refund(uuid,text) to authenticated;