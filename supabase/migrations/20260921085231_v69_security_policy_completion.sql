
create policy "package_inventory_consumptions_service_admin_read"
on public.package_inventory_consumptions for select
to authenticated
using (
 exists(select 1 from public.admin_users au where au.user_id=(select auth.uid()) and au.active=true)
);
revoke execute on function public.st_estimatedextent(text,text) from anon,authenticated;
revoke execute on function public.st_estimatedextent(text,text,text) from anon,authenticated;
revoke execute on function public.st_estimatedextent(text,text,text,boolean) from anon,authenticated;
