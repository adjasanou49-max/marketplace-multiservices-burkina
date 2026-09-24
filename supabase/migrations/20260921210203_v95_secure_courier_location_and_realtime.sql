
drop policy if exists courier_locations_courier_insert on public.courier_locations;

create policy courier_locations_courier_insert
on public.courier_locations
for insert
to authenticated
with check (
  courier_id = auth.uid()
  and private.has_role('COURIER'::public.user_role)
);

create or replace function public.record_courier_location(
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy_m numeric default null
)
returns bigint
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := auth.uid();
  v_id bigint;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if not private.has_role('COURIER'::public.user_role) then
    raise exception 'courier_role_required' using errcode = '42501';
  end if;

  if p_latitude is null or p_latitude < -90 or p_latitude > 90 then
    raise exception 'latitude_invalid' using errcode = '22023';
  end if;

  if p_longitude is null or p_longitude < -180 or p_longitude > 180 then
    raise exception 'longitude_invalid' using errcode = '22023';
  end if;

  if p_accuracy_m is not null and p_accuracy_m < 0 then
    raise exception 'accuracy_invalid' using errcode = '22023';
  end if;

  insert into public.courier_locations(
    courier_id,
    location,
    accuracy_m,
    recorded_at
  )
  values(
    v_user,
    public.st_setsrid(
      public.st_makepoint(p_longitude, p_latitude),
      4326
    )::public.geography,
    p_accuracy_m,
    now()
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.record_courier_location(double precision,double precision,numeric) from public;
revoke all on function public.record_courier_location(double precision,double precision,numeric) from anon;
revoke all on function public.record_courier_location(double precision,double precision,numeric) from authenticated;
grant execute on function public.record_courier_location(double precision,double precision,numeric) to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'courier_locations'
  ) then
    alter publication supabase_realtime add table public.courier_locations;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'delivery_events'
  ) then
    alter publication supabase_realtime add table public.delivery_events;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end
$$;
