
create policy admin_roles_self_read on public.admin_roles for select to authenticated using(id in(select admin_role_id from public.admin_users where user_id=auth.uid()));
create policy coupon_usage_own on public.coupon_usage for select to authenticated using(user_id=auth.uid());
create policy coupon_usage_insert on public.coupon_usage for insert to authenticated with check(user_id=auth.uid());
create policy share_classes_company_member_read on public.share_classes for select to authenticated using(company_id in(select company_id from public.company_members where user_id=auth.uid()));
revoke execute on function public.handle_new_user() from anon, authenticated;
