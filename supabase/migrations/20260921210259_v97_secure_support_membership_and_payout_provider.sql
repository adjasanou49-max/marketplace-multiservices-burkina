
drop policy if exists conversation_members_self_insert on public.conversation_members;

create or replace function public.create_support_conversation()
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := auth.uid();
  v_support uuid;
  v_conversation uuid;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode='42501';
  end if;

  select ur.user_id
    into v_support
  from public.user_roles ur
  where ur.role in ('SUPPORT'::public.user_role,'ADMIN'::public.user_role,'SUPER_ADMIN'::public.user_role)
    and ur.user_id <> v_user
  order by case
    when ur.role = 'SUPPORT'::public.user_role then 1
    when ur.role = 'ADMIN'::public.user_role then 2
    else 3
  end
  limit 1;

  if v_support is null then
    raise exception 'support_unavailable';
  end if;

  select c.id
    into v_conversation
  from public.conversations c
  join public.conversation_members cm1 on cm1.conversation_id=c.id and cm1.user_id=v_user
  join public.conversation_members cm2 on cm2.conversation_id=c.id and cm2.user_id=v_support
  where c.type='SUPPORT'
  order by c.created_at desc
  limit 1;

  if v_conversation is null then
    insert into public.conversations(type)
    values('SUPPORT')
    returning id into v_conversation;

    insert into public.conversation_members(conversation_id,user_id)
    values(v_conversation,v_user),(v_conversation,v_support)
    on conflict do nothing;
  end if;

  return v_conversation;
end;
$$;

revoke all on function public.create_support_conversation() from public;
revoke all on function public.create_support_conversation() from anon;
revoke all on function public.create_support_conversation() from authenticated;
grant execute on function public.create_support_conversation() to authenticated;

do $patch$
declare
  def text;
begin
  select pg_get_functiondef(p.oid)
  into def
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='request_seller_payout_secure'
    and pg_get_function_identity_arguments(p.oid)='p_seller_id uuid, p_amount numeric, p_provider text';

  def := replace(
    def,
    ' if p_provider is null or length(trim(p_provider))=0 then raise exception ''provider_required''; end if;',
    ' if p_provider is null or upper(trim(p_provider)) not in (''ORANGE_MONEY'',''WAVE'',''MOOV_MONEY'') then raise exception ''provider_invalid''; end if;'
  );
  def := replace(
    def,
    'values(p_seller_id,p_amount,''XOF'',trim(p_provider),''PENDING'')',
    'values(p_seller_id,p_amount,''XOF'',upper(trim(p_provider)),''PENDING'')'
  );
  execute def;
end
$patch$;
