create or replace function public.admin_send_test_notification(
  p_title text default 'Test Marketplace Burkina',
  p_body text default 'Les notifications push fonctionnent.'
)
returns uuid
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_id uuid;
begin
  if v_user is null or not private.is_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;

  if length(trim(coalesce(p_title,''))) = 0 or length(trim(coalesce(p_title,''))) > 120 then
    raise exception 'invalid_title';
  end if;

  if length(trim(coalesce(p_body,''))) = 0 or length(trim(coalesce(p_body,''))) > 500 then
    raise exception 'invalid_body';
  end if;

  insert into public.notifications(user_id,type,title,body,data)
  values(
    v_user,
    'push_test',
    trim(p_title),
    trim(p_body),
    jsonb_build_object('type','push_test','route','/notifications')
  )
  returning id into v_id;

  return v_id;
end;
$function$;

revoke all on function public.admin_send_test_notification(text,text) from public;
revoke all on function public.admin_send_test_notification(text,text) from anon;
grant execute on function public.admin_send_test_notification(text,text) to authenticated;