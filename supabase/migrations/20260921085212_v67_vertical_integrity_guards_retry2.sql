
alter table public.restaurant_menu_items drop constraint if exists restaurant_menu_items_price_nonnegative;
alter table public.restaurant_menu_items add constraint restaurant_menu_items_price_nonnegative check (price >= 0);
alter table public.transport_trips drop constraint if exists transport_trips_price_nonnegative;
alter table public.transport_trips add constraint transport_trips_price_nonnegative check (price >= 0);
alter table public.mechanic_quotes drop constraint if exists mechanic_quotes_amount_nonnegative;
alter table public.mechanic_quotes add constraint mechanic_quotes_amount_nonnegative check (amount >= 0);
alter table public.service_quotes drop constraint if exists service_quotes_amount_nonnegative;
alter table public.service_quotes add constraint service_quotes_amount_nonnegative check (amount >= 0);
create index if not exists idx_restaurant_menu_items_menu_active on public.restaurant_menu_items(menu_id,active);
create index if not exists idx_transport_trips_route_date on public.transport_trips(route_id,departure_at);
create index if not exists idx_mechanic_requests_status_created on public.mechanic_requests(status,created_at);
create index if not exists idx_service_requests_status_created on public.service_requests(status,created_at);
create or replace function public.accept_mechanic_quote(p_quote_id uuid) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_request uuid; v_id uuid;
begin
 select request_id into v_request from public.mechanic_quotes where id=p_quote_id and status='PENDING';
 if v_request is null then raise exception 'quote_not_available'; end if;
 if not exists(select 1 from public.mechanic_requests where id=v_request and customer_id=(select auth.uid()) and status in ('REQUESTED','QUOTED')) then raise exception 'not_authorized'; end if;
 update public.mechanic_quotes set status='ACCEPTED' where id=p_quote_id returning id into v_id;
 update public.mechanic_requests set status='ACCEPTED' where id=v_request;
 update public.mechanic_quotes set status='REJECTED' where request_id=v_request and id<>p_quote_id and status='PENDING';
 return v_id;
end; $$;
revoke all on function public.accept_mechanic_quote(uuid) from public,anon,authenticated;
grant execute on function public.accept_mechanic_quote(uuid) to service_role;
create or replace function public.create_transport_booking_secure(p_trip_id uuid,p_quantity integer,p_passenger jsonb) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_id uuid; v_price numeric; v_capacity integer; v_reserved integer;
begin
 if (select auth.uid()) is null then raise exception 'not_authenticated'; end if;
 if p_quantity <= 0 then raise exception 'quantity_invalid'; end if;
 select tt.price,tv.seat_capacity into v_price,v_capacity from public.transport_trips tt join public.transport_vehicles tv on tv.id=tt.vehicle_id where tt.id=p_trip_id and tt.status='SCHEDULED' for update;
 if v_price is null then raise exception 'trip_unavailable'; end if;
 select coalesce(sum(quantity),0) into v_reserved from public.transport_bookings where trip_id=p_trip_id and status in ('RESERVED','PAID');
 if v_reserved+p_quantity > v_capacity then raise exception 'capacity_exceeded'; end if;
 insert into public.transport_bookings(trip_id,customer_id,quantity,total_amount,status,passenger_data)
 values(p_trip_id,(select auth.uid()),p_quantity,v_price*p_quantity,'RESERVED',coalesce(p_passenger,'{}'::jsonb)) returning id into v_id;
 return v_id;
end; $$;
revoke all on function public.create_transport_booking_secure(uuid,integer,jsonb) from public,anon,authenticated;
grant execute on function public.create_transport_booking_secure(uuid,integer,jsonb) to service_role;
