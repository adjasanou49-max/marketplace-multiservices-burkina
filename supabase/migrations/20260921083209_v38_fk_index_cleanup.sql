
drop index if exists public.idx_messages_conversation_created;
drop index if exists public.uq_notification_device_token;
drop index if exists public.idx_transport_tickets_booking;

create index if not exists idx_fk_courier_earnings_assignment on public.courier_earnings(delivery_assignment_id);
create index if not exists idx_fk_courier_incidents_assignment on public.courier_incidents(delivery_assignment_id);
create index if not exists idx_fk_courier_incidents_package on public.courier_incidents(package_id);
create index if not exists idx_fk_delivery_events_actor on public.delivery_events(actor_id);
create index if not exists idx_fk_mechanic_incidents_mechanic on public.mechanic_incidents(mechanic_id);
create index if not exists idx_fk_mechanic_incidents_reporter on public.mechanic_incidents(reporter_id);
create index if not exists idx_fk_mechanic_incidents_request on public.mechanic_incidents(request_id);
create index if not exists idx_fk_mechanic_intervention_events_actor on public.mechanic_intervention_events(actor_id);
create index if not exists idx_fk_mechanic_intervention_events_intervention on public.mechanic_intervention_events(intervention_id);
create index if not exists idx_fk_mechanic_interventions_mechanic on public.mechanic_interventions(mechanic_id);
create index if not exists idx_fk_mechanic_interventions_quote on public.mechanic_interventions(quote_id);
create index if not exists idx_fk_mechanic_quotes_mechanic on public.mechanic_quotes(mechanic_id);
create index if not exists idx_fk_mechanic_reviews_customer on public.mechanic_reviews(customer_id);
create index if not exists idx_fk_mechanic_reviews_mechanic on public.mechanic_reviews(mechanic_id);
create index if not exists idx_fk_transport_boarding_actor on public.transport_boarding_events(actor_id);
create index if not exists idx_fk_transport_boarding_ticket on public.transport_boarding_events(ticket_id);
create index if not exists idx_fk_transport_checkins_checked_by on public.transport_checkins(checked_by);
create index if not exists idx_fk_transport_drivers_user on public.transport_drivers(user_id);
create index if not exists idx_fk_transport_trip_stops_station on public.transport_trip_stops(station_id);
