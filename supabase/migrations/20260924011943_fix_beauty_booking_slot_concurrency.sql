create or replace function public.create_beauty_booking(
  p_service_id uuid,
  p_scheduled_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path to 'public','private'
as $function$
declare
  v_user uuid := auth.uid();
  v_active boolean;
  v_price numeric;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if p_service_id is null or p_scheduled_at is null then
    raise exception 'INVALID_REQUEST';
  end if;

  if p_scheduled_at <= now() then
    raise exception 'INVALID_SCHEDULE';
  end if;

  select active, price
    into v_active, v_price
  from public.beauty_services
  where id = p_service_id
  for update;

  if not found or not v_active then
    raise exception 'BEAUTY_SERVICE_NOT_AVAILABLE';
  end if;

  if exists (
    select 1
    from public.beauty_bookings b
    where b.service_id = p_service_id
      and b.status in ('REQUESTED','CONFIRMED')
      and abs(extract(epoch from (b.scheduled_at - p_scheduled_at))) < 3600
  ) then
    raise exception 'TIME_SLOT_UNAVAILABLE';
  end if;

  insert into public.beauty_bookings(
    service_id,
    customer_id,
    scheduled_at,
    status,
    amount
  )
  values(
    p_service_id,
    v_user,
    p_scheduled_at,
    'REQUESTED',
    coalesce(v_price,0)
  )
  returning id into v_id;

  return v_id;
end;
$function$;
