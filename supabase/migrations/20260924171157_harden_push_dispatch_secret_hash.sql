begin;

create or replace function public.verify_push_dispatch_secret(p_candidate text)
returns boolean
language sql
security definer
set search_path to 'pg_catalog', 'public', 'vault', 'extensions'
as $function$
  select coalesce(
    encode(extensions.digest(trim(coalesce(p_candidate,'')), 'sha256'),'hex') =
      (select decrypted_secret
       from vault.decrypted_secrets
       where name='push_dispatch_secret_hash'
       limit 1),
    false
  );
$function$;

revoke all on function public.verify_push_dispatch_secret(text) from public, anon, authenticated;
grant execute on function public.verify_push_dispatch_secret(text) to service_role;

commit;