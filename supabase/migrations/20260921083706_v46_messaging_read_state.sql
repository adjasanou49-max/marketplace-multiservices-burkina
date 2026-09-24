
create table if not exists public.conversation_reads(
 conversation_id uuid not null references public.conversations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 last_read_at timestamptz not null default now(),
 primary key(conversation_id,user_id)
);
alter table public.conversation_reads enable row level security;

create policy "conversation_reads_member_all" on public.conversation_reads for all to authenticated
using (user_id=(select auth.uid()) and exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_reads.conversation_id and cm.user_id=(select auth.uid())))
with check (user_id=(select auth.uid()) and exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_reads.conversation_id and cm.user_id=(select auth.uid())));

create index if not exists idx_conversation_reads_user on public.conversation_reads(user_id,last_read_at desc);

create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns boolean language plpgsql security invoker
set search_path=pg_catalog,public
as $$
begin
 insert into public.conversation_reads(conversation_id,user_id,last_read_at)
 values(p_conversation_id,(select auth.uid()),now())
 on conflict(conversation_id,user_id) do update set last_read_at=excluded.last_read_at;
 return true;
end $$;
revoke execute on function public.mark_conversation_read(uuid) from public,anon;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
