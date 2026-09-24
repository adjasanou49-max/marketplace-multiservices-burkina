
create or replace function public.create_accommodation_booking(
  p_unit_id uuid,
  p_check_in date,
  p_check_out date,
  p_guests integer
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_quantity integer;
  v_capacity integer;
  v_price numeric;
  v_unit_active boolean;
  v_accommodation_active boolean;
  v_verified verification_status;
  v_nights integer;
  v_total numeric;
  v_booked integer;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_check_in is null or p_check_out is null or p_check_out <= p_check_in then
    raise exception 'INVALID_STAY_PERIOD';
  end if;
  if p_guests is null or p_guests < 1 then
    raise exception 'INVALID_GUEST_COUNT';
  end if;

  select u.quantity, u.capacity, u.price_per_night, u.active,
         a.verification_status, a.active
    into v_quantity, v_capacity, v_price, v_unit_active,
         v_verified, v_accommodation_active
  from public.accommodation_units u
  join public.accommodations a on a.id = u.accommodation_id
  where u.id = p_unit_id
  for update of u;

  if not found
     or not v_unit_active
     or not v_accommodation_active
     or v_verified <> 'VERIFIED' then
    raise exception 'ACCOMMODATION_NOT_AVAILABLE';
  end if;

  if p_guests > v_capacity then
    raise exception 'CAPACITY_EXCEEDED';
  end if;

  select count(*)
    into v_booked
  from public.accommodation_bookings b
  where b.unit_id = p_unit_id
    and b.status in ('REQUESTED','CONFIRMED','CHECKED_IN')
    and b.check_in < p_check_out
    and b.check_out > p_check_in;

  if v_booked >= v_quantity then
    raise exception 'ACCOMMODATION_SOLD_OUT';
  end if;

  v_nights := p_check_out - p_check_in;
  v_total := v_price * v_nights;

  insert into public.accommodation_bookings(
    unit_id, customer_id, check_in, check_out, guests, status, total_amount
  )
  values(
    p_unit_id, v_user, p_check_in, p_check_out, p_guests, 'REQUESTED', v_total
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.create_accommodation_booking(uuid,date,date,integer) from public, anon;
grant execute on function public.create_accommodation_booking(uuid,date,date,integer) to authenticated;
