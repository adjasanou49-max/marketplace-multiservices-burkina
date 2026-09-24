
create policy transport_vehicle_public_read on public.transport_vehicles
for select to anon,authenticated using(active=true);
