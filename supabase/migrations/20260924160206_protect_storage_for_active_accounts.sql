begin;

drop policy if exists storage_active_account_guard on storage.objects;
create policy storage_active_account_guard
on storage.objects
as restrictive
for all
to authenticated
using ((select private.is_active_account()))
with check ((select private.is_active_account()));

commit;