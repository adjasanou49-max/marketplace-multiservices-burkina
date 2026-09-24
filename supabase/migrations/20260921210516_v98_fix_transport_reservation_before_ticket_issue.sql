
create or replace function public.create_transport_booking_secure(
  p_trip_id uuid,
  p_quantity integer,
  p_passenger jsonb
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_id uuid;
  v_price numeric;
  v_capacity integer;
  v_reserved integer;
  v_passenger_name text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode='42501';
  end if;

  if p_trip_id is null or p_quantity is null or p_quantity <= 0 or p_quantity > 20 then
    raise exception 'quantity_invalid' using errcode='22023';
  end if;

  v_passenger_name := nullif(trim(coalesce(p_passenger->>'name','')),'');

  if v_passenger_name is null or length(v_passenger_name) > 150 then
    raise exception 'passenger_name_invalid' using errcode='22023';
  end if;

  select tt.price, tv.seat_capacity
  into v_price, v_capacity
  from public.transport_trips tt
  join public.transport_vehicles tv on tv.id = tt.vehicle_id
  where tt.id = p_trip_id
    and tt.status = 'SCHEDULED'
  for update;

  if v_price is null or v_capacity is null then
    raise exception 'trip_unavailable';
  end if;

  select coalesce(sum(quantity),0)
  into v_reserved
  from public.transport_bookings
  where trip_id = p_trip_id
    and status in ('RESERVED','PAID','ISSUED');

  if v_reserved + p_quantity > v_capacity then
    raise exception 'capacity_exceeded';
  end if;

  insert into public.transport_bookings(
    trip_id, customer_id, quantity, total_amount, status
  )
  values(
    p_trip_id,
    auth.uid(),
    p_quantity,
    v_price * p_quantity,
    'RESERVED'
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.create_transport_booking_secure(uuid,integer,jsonb) from public;
revoke all on function public.create_transport_booking_secure(uuid,integer,jsonb) from anon;
revoke all on function public.create_transport_booking_secure(uuid,integer,jsonb) from authenticated;
grant execute on function public.create_transport_booking_secure(uuid,integer,jsonb) to authenticated;
