
revoke execute on function public.request_seller_payout(numeric) from authenticated;
revoke execute on function public.set_account_status(uuid,text,text) from authenticated;

drop policy if exists "seller_payouts_owner_read" on public.seller_payouts;

drop index if exists public.idx_seller_ledger_seller_created;
drop index if exists public.idx_seller_payouts_seller_status;
