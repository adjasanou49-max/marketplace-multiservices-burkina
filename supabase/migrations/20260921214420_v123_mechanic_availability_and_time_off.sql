
create or replace function public.set_mechanic_availability(
  p_status text,
  p_starts_at timestamptz default now(),
  p_ends_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_user uuid := (select auth.uid());
  v_mechanic uuid;
  v_status text := upper(trim(coalesce(p_status,'')));
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  select id into v_mechanic from public.mechanics where user_id=v_user limit 1;
  if v_mechanic is null then raise exception 'mechanic_profile_not_found'; end if;

  if v_status not in ('AVAILABLE','IN_10_MIN','IN_20_MIN','IN_30_MIN','UNAVAILABLE') then
    raise exception 'availability_status_invalid';
  end if;
  if p_starts_at is null then raise exception 'availability_start_required'; end if;
  if p_ends_at is not null and p_ends_at <= p_starts_at then
    raise exception 'availability_period_invalid';
  end if;

  update public.mechanic_availability
  set ends_at=now()
  where mechanic_id=v_mechanic
    and starts_at <= now()
    and (ends_at is null or ends_at > now());

  insert into public.mechanic_availability(mechanic_id,status,starts_at,ends_at)
  values(v_mechanic,v_status,p_starts_at,p_ends_at)
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.schedule_mechanic_time_off(
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
  v_user uuid := (select auth.uid());
  v_mechanic uuid;
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_starts_at is null or p_ends_at is null or p_ends_at <= p_starts_at then
    raise exception 'time_off_period_invalid';
  end if;
  select id into v_mechanic from public.mechanics where user_id=v_user limit 1;
  if v_mechanic is null then raise exception 'mechanic_profile_not_found'; end if;

  if exists(
    select 1 from public.mechanic_time_off
    where mechanic_id=v_mechanic
      and starts_at < p_ends_at
      and ends_at > p_starts_at
  ) then
    raise exception 'time_off_conflict';
  end if;

  insert into public.mechanic_time_off(
    mechanic_id,reason,starts_at,ends_at
  )
  values(
    v_mechanic,nullif(trim(coalesce(p_reason,'')),''),
    p_starts_at,p_ends_at
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.set_mechanic_availability(text,timestamptz,timestamptz) from public,anon;
revoke all on function public.schedule_mechanic_time_off(timestamptz,timestamptz,text) from public,anon;
grant execute on function public.set_mechanic_availability(text,timestamptz,timestamptz) to authenticated;
grant execute on function public.schedule_mechanic_time_off(timestamptz,timestamptz,text) to authenticated;
