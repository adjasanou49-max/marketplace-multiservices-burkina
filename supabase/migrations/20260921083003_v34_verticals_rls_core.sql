
create policy "delivery_events_participants_read" on public.delivery_events for select to authenticated using (
 exists(select 1 from public.order_packages op join public.order_groups og on og.id=op.order_group_id join public.orders o on o.id=og.order_id where op.id=delivery_events.package_id and o.customer_id=(select auth.uid()))
 or exists(select 1 from public.delivery_assignments da where da.package_id=delivery_events.package_id and da.courier_id=(select auth.uid()))
);
create policy "courier_earnings_owner_read" on public.courier_earnings for select to authenticated using (courier_id=(select auth.uid()));
create policy "courier_incidents_owner_read" on public.courier_incidents for select to authenticated using (courier_id=(select auth.uid()));
create policy "courier_incidents_owner_insert" on public.courier_incidents for insert to authenticated with check (courier_id=(select auth.uid()));
create policy "transport_driver_self_read" on public.transport_drivers for select to authenticated using (user_id=(select auth.uid()));
create policy "transport_checkin_customer_read" on public.transport_checkins for select to authenticated using (
 exists(select 1 from public.transport_tickets tt join public.transport_bookings tb on tb.id=tt.booking_id where tt.id=transport_checkins.ticket_id and tb.customer_id=(select auth.uid()))
);
create policy "transport_boarding_event_self_read" on public.transport_boarding_events for select to authenticated using (actor_id=(select auth.uid()));
create policy "mechanic_quote_customer_read" on public.mechanic_quotes for select to authenticated using (
 exists(select 1 from public.mechanic_requests mr where mr.id=mechanic_quotes.request_id and mr.customer_id=(select auth.uid()))
);
create policy "mechanic_intervention_customer_read" on public.mechanic_interventions for select to authenticated using (
 exists(select 1 from public.mechanic_requests mr where mr.id=mechanic_interventions.request_id and mr.customer_id=(select auth.uid()))
);
create policy "mechanic_review_customer_manage" on public.mechanic_reviews for all to authenticated using (customer_id=(select auth.uid())) with check (customer_id=(select auth.uid()));
