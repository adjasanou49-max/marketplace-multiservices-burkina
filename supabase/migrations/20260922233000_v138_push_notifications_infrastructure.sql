create extension if not exists pg_net;
create extension if not exists pg_cron;

do $bootstrap$
begin
  if not exists (
    select 1 from vault.decrypted_secrets where name='project_url'
  ) then
    perform vault.create_secret(
      'https://dzhhsoikzxibmngjzcch.supabase.co',
      'project_url',
      'Supabase project URL for push dispatch',
      null
    );
  end if;

  if not exists (
    select 1 from vault.decrypted_secrets where name='push_dispatch_secret'
  ) then
    perform vault.create_secret(
      encode(gen_random_bytes(48),'hex'),
      'push_dispatch_secret',
      'Internal secret for notification push dispatch',
      null
    );
  end if;
end
$bootstrap$;

create index if not exists idx_notification_devices_user_active
on public.notification_devices(user_id,active);

create index if not exists idx_notifications_push_queue
on public.notifications(created_at)
where push_sent_at is null;

create or replace function public.register_notification_device(
  p_platform text,
  p_push_token text
)
returns uuid
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_platform text := upper(trim(coalesce(p_platform,'')));
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if v_platform not in ('ANDROID','IOS') then raise exception 'invalid_platform'; end if;
  if nullif(trim(p_push_token),'') is null then raise exception 'invalid_device'; end if;

  insert into public.notification_devices(
    user_id,platform,push_token,active,last_seen_at
  )
  values(v_user,v_platform,trim(p_push_token),true,now())
  on conflict(push_token) do update set
    user_id=excluded.user_id,
    platform=excluded.platform,
    active=true,
    last_seen_at=now();

  select id into v_id
  from public.notification_devices
  where push_token=trim(p_push_token)
    and user_id=v_user
  limit 1;

  return v_id;
end;
$function$;

revoke all on function public.register_notification_device(text,text) from public;
revoke all on function public.register_notification_device(text,text) from anon;
grant execute on function public.register_notification_device(text,text) to authenticated;

create or replace function public.deactivate_notification_device(p_push_token text)
returns boolean
language plpgsql
security invoker
set search_path to pg_catalog, public
as $function$
begin
  update public.notification_devices
  set active=false,last_seen_at=now()
  where user_id=(select auth.uid())
    and push_token=trim(p_push_token);
  return true;
end;
$function$;

revoke all on function public.deactivate_notification_device(text) from public;
revoke all on function public.deactivate_notification_device(text) from anon;
grant execute on function public.deactivate_notification_device(text) to authenticated;

create or replace function public.verify_push_dispatch_secret(p_candidate text)
returns boolean
language sql
security definer
set search_path to pg_catalog, public, vault
as $function$
  select coalesce(
    nullif(trim(p_candidate),'') =
      (select decrypted_secret from vault.decrypted_secrets where name='push_dispatch_secret' limit 1),
    false
  );
$function$;

revoke all on function public.verify_push_dispatch_secret(text) from public;
revoke all on function public.verify_push_dispatch_secret(text) from anon;
revoke all on function public.verify_push_dispatch_secret(text) from authenticated;
grant execute on function public.verify_push_dispatch_secret(text) to service_role;

create or replace function public.trigger_push_notification()
returns trigger
language plpgsql
security definer
set search_path to pg_catalog, public, net, vault
as $function$
declare
  v_url text;
  v_secret text;
begin
  v_url := (select decrypted_secret from vault.decrypted_secrets where name='project_url' limit 1);
  v_secret := (select decrypted_secret from vault.decrypted_secrets where name='push_dispatch_secret' limit 1);
  if v_url is null or v_secret is null then return new; end if;

  perform net.http_post(
    url := v_url || '/functions/v1/dispatch-push-notifications',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-push-dispatch-secret',v_secret
    ),
    body := jsonb_build_object('notification_id',new.id),
    timeout_milliseconds := 5000
  );
  return new;
exception when others then
  return new;
end;
$function$;

drop trigger if exists notifications_push_after_insert on public.notifications;
create trigger notifications_push_after_insert
after insert on public.notifications
for each row
execute function public.trigger_push_notification();

select cron.schedule(
  'dispatch-notifications-every-minute',
  '* * * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name='project_url' limit 1)
      || '/functions/v1/dispatch-push-notifications',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-push-dispatch-secret',
      (select decrypted_secret from vault.decrypted_secrets where name='push_dispatch_secret' limit 1)
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 5000
  ) as request_id;
  $job$
);