
do $$
declare r record;
begin
  for r in
    select schemaname, tablename, policyname, cmd, qual, with_check
    from pg_policies
    where schemaname='public'
      and (
        coalesce(qual,'') like '%auth.uid()%'
        or coalesce(with_check,'') like '%auth.uid()%'
      )
  loop
    if r.qual is not null then
      execute format(
        'alter policy %I on %I.%I using (%s)',
        r.policyname, r.schemaname, r.tablename,
        regexp_replace(r.qual, 'auth\.uid\(\)', '(select auth.uid())', 'g')
      );
    end if;
    if r.with_check is not null then
      execute format(
        'alter policy %I on %I.%I with check (%s)',
        r.policyname, r.schemaname, r.tablename,
        regexp_replace(r.with_check, 'auth\.uid\(\)', '(select auth.uid())', 'g')
      );
    end if;
  end loop;
end $$;

drop policy if exists messages_member_read on public.messages;
create policy messages_member_read on public.messages
for select to authenticated
using (
  exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = messages.conversation_id
      and cm.user_id = (select auth.uid())
  )
);

drop policy if exists messages_member_insert on public.messages;
create policy messages_member_insert on public.messages
for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = messages.conversation_id
      and cm.user_id = (select auth.uid())
  )
);
