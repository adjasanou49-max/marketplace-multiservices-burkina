begin;

create or replace function public.register_notification_device(
  p_platform text,
  p_push_token text
)
returns uuid
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_user uuid := (select auth.uid());
  v_platform text := upper(trim(coalesce(p_platform,'')));
  v_token text := trim(coalesce(p_push_token,''));
  v_existing_user uuid;
  v_id uuid;
begin
  perform private.require_active_account();

  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  if v_platform not in ('ANDROID','IOS') then
    raise exception 'invalid_platform';
  end if;

  if v_token = '' or length(v_token) > 4096 then
    raise exception 'invalid_device';
  end if;

  select nd.user_id
  into v_existing_user
  from public.notification_devices nd
  where nd.push_token = v_token
  for update;

  if v_existing_user is not null and v_existing_user <> v_user then
    raise exception 'device_already_registered' using errcode='42501';
  end if;

  insert into public.notification_devices(
    user_id, platform, push_token, active, last_seen_at
  )
  values(
    v_user, v_platform, v_token, true, now()
  )
  on conflict(push_token) do update set
    platform=excluded.platform,
    active=true,
    last_seen_at=now();

  select id
  into v_id
  from public.notification_devices
  where push_token=v_token
    and user_id=v_user
  limit 1;

  return v_id;
end;
$function$;

revoke all on function public.register_notification_device(text,text) from public, anon;
grant execute on function public.register_notification_device(text,text) to authenticated;

commit;