
alter table public.transport_seats enable row level security;
alter table public.transport_trip_stops enable row level security;
alter table public.mechanic_intervention_events enable row level security;
alter table public.mechanic_incidents enable row level security;

create policy "transport_seats_authenticated_read" on public.transport_seats for select to authenticated using (active=true);
create policy "transport_trip_stops_authenticated_read" on public.transport_trip_stops for select to authenticated using (true);
create policy "mechanic_intervention_events_participant_read" on public.mechanic_intervention_events for select to authenticated using (
 exists(select 1 from public.mechanic_interventions mi join public.mechanic_requests mr on mr.id=mi.request_id where mi.id=mechanic_intervention_events.intervention_id and mr.customer_id=(select auth.uid()))
 or actor_id=(select auth.uid())
);
create policy "mechanic_incidents_mechanic_read" on public.mechanic_incidents for select to authenticated using (
 exists(select 1 from public.mechanics m where m.id=mechanic_incidents.mechanic_id and m.user_id=(select auth.uid()))
);
