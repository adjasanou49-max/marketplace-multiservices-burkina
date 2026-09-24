
drop policy if exists marketplace_modules_admin_manage on public.marketplace_modules;
create policy marketplace_modules_admin_write
on public.marketplace_modules
for all
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

drop policy if exists marketplace_modules_client_read on public.marketplace_modules;
create policy marketplace_modules_client_read
on public.marketplace_modules
for select
to anon, authenticated
using (enabled = true and not (select private.is_admin()));

revoke execute on function public.is_admin_actor() from anon, authenticated;
revoke execute on function public.st_estimatedextent(text, text) from anon, authenticated, public;
revoke execute on function public.st_estimatedextent(text, text, text) from anon, authenticated, public;
revoke execute on function public.st_estimatedextent(text, text, text, boolean) from anon, authenticated, public;
