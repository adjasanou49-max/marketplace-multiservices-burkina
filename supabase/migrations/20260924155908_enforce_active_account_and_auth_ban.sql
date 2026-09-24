begin;

create or replace function private.is_active_account()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.status = 'ACTIVE'::public.account_status
  );
$function$;

revoke all on function private.is_active_account() from public, anon, authenticated;

do $block$
declare
  t record;
begin
  for t in
    select n.nspname as schema_name, c.relname as table_name
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r','p')
      and c.relrowsecurity
      and c.relname <> 'spatial_ref_sys'
  loop
    if not exists (
      select 1 from pg_policies p
      where p.schemaname=t.schema_name
        and p.tablename=t.table_name
        and p.policyname='active_account_guard'
    ) then
      execute format(
        'create policy active_account_guard on %I.%I as restrictive for all to authenticated using ((select private.is_active_account())) with check ((select private.is_active_account()))',
        t.schema_name,t.table_name
      );
    end if;
  end loop;
end;
$block$;

create or replace function public.admin_set_account_status(
  p_user_id uuid,
  p_status public.account_status,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
begin
  if not public.is_admin_actor() then
    raise exception 'admin access required' using errcode='42501';
  end if;
  if p_user_id=auth.uid() and p_status in ('SUSPENDED','BLOCKED') then
    raise exception 'cannot disable current admin account' using errcode='22023';
  end if;
  update public.profiles set status=p_status,updated_at=now() where id=p_user_id;
  if not found then raise exception 'user not found' using errcode='P0002'; end if;

  update auth.users
  set banned_until = case
    when p_status='ACTIVE'::public.account_status then null
    else now()+interval '100 years'
  end
  where id=p_user_id;

  insert into public.account_actions(target_user_id,actor_id,action,reason)
  values(p_user_id,auth.uid(),p_status::text,p_reason);
end;
$function$;

revoke all on function public.admin_set_account_status(uuid,public.account_status,text) from public,anon;
grant execute on function public.admin_set_account_status(uuid,public.account_status,text) to authenticated;

create or replace function public.set_account_status(
  p_target_user uuid,
  p_action text,
  p_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_actor uuid := (select auth.uid());
  v_status public.account_status;
begin
  if v_actor is null or not public.is_admin() then raise exception 'admin_required'; end if;
  if p_target_user is null then raise exception 'invalid_user'; end if;
  if p_target_user=v_actor then raise exception 'cannot_modify_self'; end if;

  case upper(trim(p_action))
    when 'SUSPEND' then v_status:='SUSPENDED';
    when 'BLOCK' then v_status:='BLOCKED';
    when 'REACTIVATE' then v_status:='ACTIVE';
    else raise exception 'invalid_account_action';
  end case;

  update public.profiles set status=v_status where id=p_target_user;
  if not found then raise exception 'user_not_found'; end if;

  update auth.users
  set banned_until = case
    when v_status='ACTIVE'::public.account_status then null
    else now()+interval '100 years'
  end
  where id=p_target_user;

  insert into public.account_actions(target_user_id,actor_id,action,reason)
  values(p_target_user,v_actor,upper(trim(p_action)),p_reason);

  insert into public.admin_change_log(actor_id,entity_type,entity_id,action,after_data)
  values(v_actor,'profile',p_target_user,upper(trim(p_action)),
         jsonb_build_object('status',v_status::text,'reason',p_reason));
  return true;
end $function$;

revoke all on function public.set_account_status(uuid,text,text) from public,anon;
grant execute on function public.set_account_status(uuid,text,text) to authenticated;

commit;