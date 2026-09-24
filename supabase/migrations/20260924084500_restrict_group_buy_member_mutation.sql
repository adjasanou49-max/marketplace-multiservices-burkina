drop policy if exists group_buy_members_own on public.group_buy_members;

create policy group_buy_members_customer_read
on public.group_buy_members
for select
to authenticated
using (user_id = auth.uid());
