create or replace function public.create_mechanic_request(
  p_vehicle_type text,
  p_problem_type text,
  p_description text default null,
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if upper(trim(coalesce(p_vehicle_type,''))) not in ('CAR','MOTORCYCLE','BICYCLE') then
    raise exception 'invalid_vehicle_type';
  end if;
  if nullif(trim(coalesce(p_problem_type,'')), '') is null then
    raise exception 'problem_required';
  end if;
  if (p_latitude is not null and (p_latitude < -90 or p_latitude > 90))
     or (p_longitude is not null and (p_longitude < -180 or p_longitude > 180)) then
    raise exception 'invalid_coordinates';
  end if;

  insert into public.mechanic_requests(
    customer_id, vehicle_type, problem_type, description,
    latitude, longitude, status
  )
  values(
    v_user,
    upper(trim(p_vehicle_type)),
    trim(p_problem_type),
    nullif(trim(p_description), ''),
    p_latitude,
    p_longitude,
    'OPEN'
  )
  returning id into v_id;

  return v_id;
end;
$function$;

revoke all on function public.create_mechanic_request(text,text,text,double precision,double precision)
  from public, anon;
grant execute on function public.create_mechanic_request(text,text,text,double precision,double precision)
  to authenticated;
