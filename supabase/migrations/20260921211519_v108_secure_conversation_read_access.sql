
create or replace function public.mark_conversation_read(
  p_conversation_id uuid
)
returns boolean
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode='42501';
  end if;

  if not exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = p_conversation_id
      and cm.user_id = auth.uid()
  ) then
    raise exception 'conversation_access_denied' using errcode='42501';
  end if;

  insert into public.conversation_reads(
    conversation_id,
    user_id,
    last_read_at
  )
  values(
    p_conversation_id,
    auth.uid(),
    now()
  )
  on conflict(conversation_id,user_id)
  do update set last_read_at=excluded.last_read_at;

  return true;
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
revoke all on function public.mark_conversation_read(uuid) from anon;
revoke all on function public.mark_conversation_read(uuid) from authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
