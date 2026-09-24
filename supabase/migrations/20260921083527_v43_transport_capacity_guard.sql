
create or replace function public.create_transport_booking(p_trip_id uuid,p_quantity integer,p_passengers jsonb default '[]'::jsonb)
returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_trip public.transport_trips%rowtype; v_capacity integer; v_booked integer; v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_quantity is null or p_quantity<1 then raise exception 'invalid_quantity'; end if;
 select * into v_trip from public.transport_trips where id=p_trip_id and status='SCHEDULED' for update;
 if not found then raise exception 'trip_unavailable'; end if;
 select seat_count into v_capacity from public.transport_vehicles where id=v_trip.vehicle_id and active=true;
 if v_capacity is not null then
   select coalesce(sum(quantity),0) into v_booked from public.transport_bookings where trip_id=p_trip_id and status in ('RESERVED','PAID','ISSUED','CHECKED_IN','BOARDED');
   if v_booked+p_quantity>v_capacity then raise exception 'insufficient_seats'; end if;
 end if;
 insert into public.transport_bookings(trip_id,customer_id,quantity,total_amount,status)
 values(p_trip_id,v_user,p_quantity,v_trip.price*p_quantity,'RESERVED') returning id into v_id;
 return v_id;
end $$;
revoke execute on function public.create_transport_booking(uuid,integer,jsonb) from public,anon,authenticated;
grant execute on function public.create_transport_booking(uuid,integer,jsonb) to service_role;
