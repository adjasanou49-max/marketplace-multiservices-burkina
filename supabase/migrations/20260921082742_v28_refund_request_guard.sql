
create or replace function public.request_refund(
 p_order_id uuid,
 p_amount numeric,
 p_reason text default null
) returns uuid
language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare
 v_user uuid := (select auth.uid());
 v_refund uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_amount <= 0 then raise exception 'invalid_refund_amount'; end if;

 if not exists (
   select 1 from public.orders
   where id=p_order_id and customer_id=v_user
 ) and not public.is_admin() then
   raise exception 'not_authorized';
 end if;

 if not exists (
   select 1 from public.payments
   where order_id=p_order_id and status in ('SUCCEEDED','PARTIALLY_REFUNDED')
 ) then
   raise exception 'no_successful_payment';
 end if;

 insert into public.refunds(payment_id,order_id,amount,currency,reason,status)
 select p.id,p_order_id,p_amount,'XOF',p_reason,'REQUESTED'
 from public.payments p
 where p.order_id=p_order_id
   and p.status in ('SUCCEEDED','PARTIALLY_REFUNDED')
 order by p.created_at asc
 limit 1
 returning id into v_refund;

 if v_refund is null then raise exception 'refund_payment_not_found'; end if;
 return v_refund;
end $$;

revoke execute on function public.request_refund(uuid,numeric,text) from public,anon,authenticated;
grant execute on function public.request_refund(uuid,numeric,text) to service_role;

create index if not exists idx_refunds_order_status
on public.refunds(order_id,status,created_at desc);
