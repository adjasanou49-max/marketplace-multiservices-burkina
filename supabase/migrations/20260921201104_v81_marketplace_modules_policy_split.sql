
drop policy if exists marketplace_modules_admin_write on public.marketplace_modules;
drop policy if exists marketplace_modules_admin_insert on public.marketplace_modules;
drop policy if exists marketplace_modules_admin_update on public.marketplace_modules;
drop policy if exists marketplace_modules_admin_delete on public.marketplace_modules;

create policy marketplace_modules_admin_insert
on public.marketplace_modules
for insert to authenticated
with check ((select private.is_admin()));

create policy marketplace_modules_admin_update
on public.marketplace_modules
for update to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy marketplace_modules_admin_delete
on public.marketplace_modules
for delete to authenticated
using ((select private.is_admin()));

drop policy if exists marketplace_modules_client_read on public.marketplace_modules;
create policy marketplace_modules_client_read
on public.marketplace_modules
for select
to anon, authenticated
using (enabled = true);
