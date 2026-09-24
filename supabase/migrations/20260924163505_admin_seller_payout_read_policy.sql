begin;

drop policy if exists admin_payouts_read on public.seller_payouts;
create policy admin_payouts_read
on public.seller_payouts
for select
to authenticated
using ((select private.is_admin()));

commit;