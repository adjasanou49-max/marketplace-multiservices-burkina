create or replace function public.schedule_mechanic_time_off(
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_user uuid := auth.uid();
  v_mechanic uuid;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select id into v_mechanic
  from public.mechanics
  where user_id = v_user
  limit 1
  for update;

  if v_mechanic is null then
    raise exception 'mechanic_not_found';
  end if;

  if p_starts_at is null or p_ends_at is null or p_ends_at <= p_starts_at then
    raise exception 'time_off_period_invalid';
  end if;

  if p_ends_at <= now() then
    raise exception 'time_off_already_finished';
  end if;

  if exists (
    select 1
    from public.mechanic_time_off t
    where t.mechanic_id = v_mechanic
      and t.starts_at < p_ends_at
      and t.ends_at > p_starts_at
  ) then
    raise exception 'time_off_overlap';
  end if;

  insert into public.mechanic_time_off(
    mechanic_id, reason, starts_at, ends_at
  )
  values(
    v_mechanic,
    nullif(trim(coalesce(p_reason,'')), ''),
    p_starts_at,
    p_ends_at
  )
  returning id into v_id;

  return v_id;
end;
$function$;
