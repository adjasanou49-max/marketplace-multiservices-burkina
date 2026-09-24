
create policy ai_tasks_owner_read on public.ai_tasks for select to authenticated
using(entity_id is not null and (entity_id in(select id from public.orders where customer_id=auth.uid())
or entity_id in(select id from public.products where shop_id in(select id from public.shops where seller_id in(select id from public.sellers where user_id=auth.uid())))));
create policy moderation_cases_restricted on public.moderation_cases for select to authenticated
using(assigned_to=auth.uid());
revoke execute on function public.handle_new_user() from public;
revoke execute on function public.handle_new_user() from anon;
revoke execute on function public.handle_new_user() from authenticated;
