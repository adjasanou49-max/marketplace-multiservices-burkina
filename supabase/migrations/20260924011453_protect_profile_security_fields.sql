create or replace function public.enforce_profile_security_fields()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  if auth.uid() is null then
    return new;
  end if;

  if public.is_admin_actor() then
    return new;
  end if;

  if new.status is distinct from old.status then
    raise exception 'profile_status_admin_only' using errcode='42501';
  end if;

  if new.verification_status is distinct from old.verification_status then
    raise exception 'profile_verification_admin_only' using errcode='42501';
  end if;

  return new;
end;
$function$;

drop trigger if exists enforce_profile_security_fields on public.profiles;

create trigger enforce_profile_security_fields
before update of status, verification_status on public.profiles
for each row
execute function public.enforce_profile_security_fields();
