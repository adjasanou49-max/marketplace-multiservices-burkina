
create or replace function public.mark_notification_read(p_notification_id uuid)
returns boolean language plpgsql security definer
set search_path=pg_catalog,public
as $$
begin
 update public.notifications set read_at=coalesce(read_at,now())
 where id=p_notification_id and user_id=(select auth.uid());
 if not found then raise exception 'notification_not_found'; end if;
 return true;
end $$;
revoke execute on function public.mark_notification_read(uuid) from public,anon,authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;

create or replace function public.register_notification_device(
 p_platform text,push_token text
) returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 if (select auth.uid()) is null then raise exception 'not_authenticated'; end if;
 if nullif(trim(p_platform),'') is null or nullif(trim(p_push_token),'') is null then raise exception 'invalid_device'; end if;
 insert into public.notification_devices(user_id,platform,push_token,active,last_seen_at)
 values((select auth.uid()),lower(trim(p_platform)),trim(p_push_token),true,now())
 on conflict(push_token) do update set user_id=excluded.user_id,platform=excluded.platform,active=true,last_seen_at=now()
 returning id into v_id;
 return v_id;
end $$;
revoke execute on function public.register_notification_device(text,text) from public,anon;
grant execute on function public.register_notification_device(text,text) to authenticated;
