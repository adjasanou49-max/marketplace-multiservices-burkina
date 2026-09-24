begin;

drop policy if exists notifications_own on public.notifications;
create policy notifications_read_own
on public.notifications
for select
to authenticated
using (user_id = (select auth.uid()));

create policy notifications_mark_read
on public.notifications
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

revoke all on table public.notifications from public, anon, authenticated;
grant select on table public.notifications to authenticated;
grant update (read_at) on table public.notifications to authenticated;

drop policy if exists user_consents_own on public.user_consents;
create policy user_consents_read_own
on public.user_consents
for select
to authenticated
using (user_id = (select auth.uid()));

create policy user_consents_insert_own
on public.user_consents
for insert
to authenticated
with check (user_id = (select auth.uid()));

revoke all on table public.user_consents from public, anon, authenticated;
grant select, insert on table public.user_consents to authenticated;

commit;