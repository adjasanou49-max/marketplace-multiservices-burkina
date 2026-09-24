
create or replace function public.request_seller_payout(p_amount numeric)
returns uuid
language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare
 v_user uuid := (select auth.uid());
 v_seller uuid;
 v_available numeric;
 v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_amount <= 0 then raise exception 'invalid_amount'; end if;

 select id into v_seller from public.sellers where user_id=v_user;
 if v_seller is null then raise exception 'seller_not_found'; end if;

 select coalesce(sum(case when entry_type in ('SALE','CREDIT') then amount else -abs(amount) end),0)
 into v_available
 from public.seller_ledger
 where seller_id=v_seller;

 v_available:=v_available-coalesce((
   select sum(amount) from public.seller_payouts
   where seller_id=v_seller and status in ('PENDING','PROCESSING')
 ),0);

 if p_amount > v_available then raise exception 'insufficient_available_balance'; end if;

 insert into public.seller_payouts(seller_id,amount,currency,status)
 values(v_seller,p_amount,'XOF','PENDING')
 returning id into v_id;

 return v_id;
end $$;

revoke execute on function public.request_seller_payout(numeric) from public,anon,authenticated;
grant execute on function public.request_seller_payout(numeric) to authenticated;

create policy "seller_payouts_owner_read"
on public.seller_payouts for select to authenticated
using (seller_id=(select id from public.sellers where user_id=(select auth.uid())));

create index if not exists idx_commissions_seller_status_created
on public.commissions(seller_id,status,created_at desc);
