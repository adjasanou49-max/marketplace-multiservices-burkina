
begin;

drop policy if exists marketplace_modules_admin_read on public.marketplace_modules;
create policy marketplace_modules_read
on public.marketplace_modules
for select
to anon, authenticated
using (
  enabled = true
  or (select private.is_admin())
);

insert into public.marketplace_modules(key,label,route,icon_name,enabled,sort_order,config)
values
('rides','Taxi / Moto / Déplacement','/rides','directions_car',true,90,'{}'::jsonb),
('rentals','Location de véhicules','/rentals','car_rental',true,100,'{}'::jsonb),
('real_estate','Immobilier','/real-estate','home_work',true,110,'{}'::jsonb),
('accommodations','Hôtels & Hébergements','/accommodations','hotel',true,120,'{}'::jsonb),
('events','Événements & Billets','/events','event',true,130,'{}'::jsonb),
('jobs','Emplois','/jobs','work',true,140,'{}'::jsonb),
('professionals','Professionnels','/professionals','engineering',true,150,'{}'::jsonb),
('agriculture','Agriculture','/agriculture','agriculture',true,160,'{}'::jsonb),
('freight','Fret & Transport de marchandises','/freight','local_shipping',true,170,'{}'::jsonb),
('health','Santé','/health','health_and_safety',true,180,'{}'::jsonb),
('beauty','Beauté & Coiffure','/beauty','content_cut',true,190,'{}'::jsonb),
('home_services','Services à domicile','/home-services','home_repair_service',true,200,'{}'::jsonb),
('digital','Services numériques','/digital','devices',true,210,'{}'::jsonb),
('training','Formations','/training','school',true,220,'{}'::jsonb),
('creative','Créatifs','/creative','camera_alt',true,230,'{}'::jsonb),
('parcels','Colis & Points relais','/parcels','inventory_2',true,240,'{}'::jsonb)
on conflict (key) do update set
  label = excluded.label,
  route = excluded.route,
  icon_name = excluded.icon_name,
  enabled = excluded.enabled,
  sort_order = excluded.sort_order,
  config = excluded.config,
  updated_at = now();

create or replace function public.create_ride_request(
  p_pickup jsonb,
  p_destination jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
  v_lat numeric;
  v_lng numeric;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if jsonb_typeof(p_pickup) <> 'object'
     or jsonb_typeof(p_destination) <> 'object' then
    raise exception 'INVALID_LOCATION';
  end if;

  begin
    v_lat := (p_pickup->>'latitude')::numeric;
    v_lng := (p_pickup->>'longitude')::numeric;
  exception when others then
    raise exception 'INVALID_PICKUP_LOCATION';
  end;

  if v_lat not between -90 and 90 or v_lng not between -180 and 180 then
    raise exception 'INVALID_PICKUP_LOCATION';
  end if;

  begin
    v_lat := (p_destination->>'latitude')::numeric;
    v_lng := (p_destination->>'longitude')::numeric;
  exception when others then
    raise exception 'INVALID_DESTINATION_LOCATION';
  end;

  if v_lat not between -90 and 90 or v_lng not between -180 and 180 then
    raise exception 'INVALID_DESTINATION_LOCATION';
  end if;

  insert into public.ride_requests(customer_id,pickup,destination,status)
  values(v_user,p_pickup,p_destination,'REQUESTED')
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.reserve_event_ticket(
  p_event_id uuid,
  p_quantity integer default 1
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_capacity integer;
  v_price numeric;
  v_active boolean;
  v_starts_at timestamptz;
  v_reserved integer;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 20 then
    raise exception 'INVALID_QUANTITY';
  end if;

  select capacity,ticket_price,active,starts_at
    into v_capacity,v_price,v_active,v_starts_at
  from public.events
  where id = p_event_id
  for update;

  if not found or not v_active then raise exception 'EVENT_NOT_AVAILABLE'; end if;
  if v_starts_at <= now() then raise exception 'EVENT_ALREADY_STARTED'; end if;

  select coalesce(sum(quantity),0)
    into v_reserved
  from public.event_bookings
  where event_id = p_event_id
    and status in ('RESERVED','PAID','CHECKED_IN','USED');

  if v_reserved + p_quantity > v_capacity then
    raise exception 'EVENT_CAPACITY_REACHED';
  end if;

  insert into public.event_bookings(event_id,customer_id,quantity,total_amount,status)
  values(p_event_id,v_user,p_quantity,v_price * p_quantity,'RESERVED')
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.create_vehicle_rental_booking(
  p_rental_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_price numeric;
  v_active boolean;
  v_verified verification_status;
  v_days integer;
  v_total numeric;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_starts_at is null or p_ends_at is null or p_ends_at <= p_starts_at then
    raise exception 'INVALID_RENTAL_PERIOD';
  end if;

  select daily_price,active,verification_status
    into v_price,v_active,v_verified
  from public.vehicle_rentals
  where id = p_rental_id
  for update;

  if not found or not v_active or v_verified <> 'VERIFIED' then
    raise exception 'RENTAL_NOT_AVAILABLE';
  end if;

  if exists (
    select 1 from public.vehicle_rental_bookings
    where rental_id = p_rental_id
      and status in ('REQUESTED','CONFIRMED','ACTIVE')
      and starts_at < p_ends_at
      and ends_at > p_starts_at
  ) then
    raise exception 'RENTAL_ALREADY_BOOKED';
  end if;

  v_days := greatest(1, ceil(extract(epoch from (p_ends_at - p_starts_at)) / 86400.0)::integer);
  v_total := v_price * v_days;

  insert into public.vehicle_rental_bookings(
    rental_id,customer_id,starts_at,ends_at,status,total_amount
  )
  values(p_rental_id,v_user,p_starts_at,p_ends_at,'REQUESTED',v_total)
  returning id into v_id;

  return v_id;
end;
$$;

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
  v_active boolean;
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
  if p_guests is null or p_guests < 1 then raise exception 'INVALID_GUEST_COUNT'; end if;

  select u.quantity,u.capacity,u.price_per_night,u.active,a.verification_status,a.active
    into v_quantity,v_capacity,v_price,v_active,v_verified,v_active
  from public.accommodation_units u
  join public.accommodations a on a.id = u.accommodation_id
  where u.id = p_unit_id
  for update of u;

  if not found or not v_active or v_verified <> 'VERIFIED' then
    raise exception 'ACCOMMODATION_NOT_AVAILABLE';
  end if;
  if p_guests > v_capacity then raise exception 'CAPACITY_EXCEEDED'; end if;

  select count(*) into v_booked
  from public.accommodation_bookings b
  where b.unit_id = p_unit_id
    and b.status in ('REQUESTED','CONFIRMED','CHECKED_IN')
    and b.check_in < p_check_out
    and b.check_out > p_check_in;

  if v_booked >= v_quantity then raise exception 'ACCOMMODATION_SOLD_OUT'; end if;

  v_nights := (p_check_out - p_check_in);
  v_total := v_price * v_nights;

  insert into public.accommodation_bookings(
    unit_id,customer_id,check_in,check_out,guests,status,total_amount
  )
  values(p_unit_id,v_user,p_check_in,p_check_out,p_guests,'REQUESTED',v_total)
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.enroll_training_course(
  p_course_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_active boolean;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select active into v_active from public.training_courses where id = p_course_id;
  if not found or not v_active then raise exception 'COURSE_NOT_AVAILABLE'; end if;

  if exists (
    select 1 from public.training_enrollments
    where course_id = p_course_id and customer_id = v_user
      and status in ('ENROLLED','PAID','COMPLETED')
  ) then
    raise exception 'ALREADY_ENROLLED';
  end if;

  insert into public.training_enrollments(course_id,customer_id,status)
  values(p_course_id,v_user,'ENROLLED')
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.create_digital_order(
  p_service_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_active boolean;
  v_price numeric;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select active,price into v_active,v_price
  from public.digital_services where id = p_service_id;

  if not found or not v_active then raise exception 'DIGITAL_SERVICE_NOT_AVAILABLE'; end if;

  insert into public.digital_orders(digital_service_id,customer_id,status,amount)
  values(p_service_id,v_user,'REQUESTED',coalesce(v_price,0))
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.create_beauty_booking(
  p_service_id uuid,
  p_scheduled_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_active boolean;
  v_price numeric;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_scheduled_at <= now() then raise exception 'INVALID_SCHEDULE'; end if;

  select active,price into v_active,v_price
  from public.beauty_services where id = p_service_id;

  if not found or not v_active then raise exception 'BEAUTY_SERVICE_NOT_AVAILABLE'; end if;

  if exists (
    select 1
    from public.beauty_bookings b
    where b.service_id = p_service_id
      and b.status in ('REQUESTED','CONFIRMED')
      and abs(extract(epoch from (b.scheduled_at - p_scheduled_at))) < 3600
  ) then
    raise exception 'TIME_SLOT_UNAVAILABLE';
  end if;

  insert into public.beauty_bookings(service_id,customer_id,scheduled_at,status,amount)
  values(p_service_id,v_user,p_scheduled_at,'REQUESTED',coalesce(v_price,0))
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.create_home_service_request(
  p_service_id uuid,
  p_scheduled_at timestamptz,
  p_address jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_active boolean;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_scheduled_at <= now() then raise exception 'INVALID_SCHEDULE'; end if;
  if jsonb_typeof(p_address) <> 'object' then raise exception 'INVALID_ADDRESS'; end if;

  select active into v_active from public.home_services where id = p_service_id;
  if not found or not v_active then raise exception 'HOME_SERVICE_NOT_AVAILABLE'; end if;

  insert into public.home_service_requests(
    service_id,customer_id,scheduled_at,address,status,agreed_amount
  )
  select p_service_id,v_user,p_scheduled_at,p_address,'REQUESTED',coalesce(starting_price,0)
  from public.home_services where id = p_service_id
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.apply_to_job(
  p_job_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_active boolean;
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select active into v_active from public.jobs where id = p_job_id;
  if not found or not v_active then raise exception 'JOB_NOT_AVAILABLE'; end if;

  if exists (
    select 1 from public.job_applications
    where job_id = p_job_id and applicant_id = v_user
  ) then
    raise exception 'ALREADY_APPLIED';
  end if;

  insert into public.job_applications(job_id,applicant_id,status)
  values(p_job_id,v_user,'SUBMITTED')
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.create_ride_request(jsonb,jsonb) from public, anon;
revoke all on function public.reserve_event_ticket(uuid,integer) from public, anon;
revoke all on function public.create_vehicle_rental_booking(uuid,timestamptz,timestamptz) from public, anon;
revoke all on function public.create_accommodation_booking(uuid,date,date,integer) from public, anon;
revoke all on function public.enroll_training_course(uuid) from public, anon;
revoke all on function public.create_digital_order(uuid) from public, anon;
revoke all on function public.create_beauty_booking(uuid,timestamptz) from public, anon;
revoke all on function public.create_home_service_request(uuid,timestamptz,jsonb) from public, anon;
revoke all on function public.apply_to_job(uuid) from public, anon;

grant execute on function public.create_ride_request(jsonb,jsonb) to authenticated;
grant execute on function public.reserve_event_ticket(uuid,integer) to authenticated;
grant execute on function public.create_vehicle_rental_booking(uuid,timestamptz,timestamptz) to authenticated;
grant execute on function public.create_accommodation_booking(uuid,date,date,integer) to authenticated;
grant execute on function public.enroll_training_course(uuid) to authenticated;
grant execute on function public.create_digital_order(uuid) to authenticated;
grant execute on function public.create_beauty_booking(uuid,timestamptz) to authenticated;
grant execute on function public.create_home_service_request(uuid,timestamptz,jsonb) to authenticated;
grant execute on function public.apply_to_job(uuid) to authenticated;

commit;
