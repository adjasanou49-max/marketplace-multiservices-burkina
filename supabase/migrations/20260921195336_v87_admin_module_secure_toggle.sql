create or replace function public.admin_set_marketplace_module_enabled(
  p_key text,
  p_enabled boolean
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_key text := nullif(trim(p_key), '');
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if not (select private.is_admin()) then
    raise exception 'admin_access_required' using errcode='42501';
  end if;
  if v_key is null then raise exception 'module_key_required'; end if;

  update public.marketplace_modules
  set enabled = coalesce(p_enabled, false),
      updated_by = v_user,
      updated_at = now()
  where key = v_key;

  if not found then raise exception 'module_not_found'; end if;

  insert into public.audit_logs(
    actor_id, action, entity_type, entity_id, metadata
  )
  select
    v_user,
    'ADMIN_MODULE_ENABLED',
    'marketplace_module',
    null,
    jsonb_build_object(
      'key', v_key,
      'enabled', p_enabled
    );

  return p_enabled;
end;
$function$;

revoke all on function public.admin_set_marketplace_module_enabled(text,boolean)
  from public, anon;
grant execute on function public.admin_set_marketplace_module_enabled(text,boolean)
  to authenticated;
