begin;

create index if not exists idx_carts_customer_id on public.carts(customer_id);
create index if not exists idx_cart_items_cart_id on public.cart_items(cart_id);
create index if not exists idx_cart_items_product_id on public.cart_items(product_id);
create index if not exists idx_cart_items_variant_id on public.cart_items(variant_id);

create index if not exists idx_orders_customer_id on public.orders(customer_id);
create index if not exists idx_order_groups_order_id on public.order_groups(order_id);
create index if not exists idx_order_groups_shop_id on public.order_groups(shop_id);
create index if not exists idx_order_items_order_group_id on public.order_items(order_group_id);
create index if not exists idx_order_items_product_id on public.order_items(product_id);
create index if not exists idx_order_items_variant_id on public.order_items(variant_id);
create index if not exists idx_order_packages_order_group_id on public.order_packages(order_group_id);

create index if not exists idx_payments_order_id on public.payments(order_id);
create index if not exists idx_payment_events_payment_id on public.payment_events(payment_id);
create index if not exists idx_refunds_order_id on public.refunds(order_id);
create index if not exists idx_refunds_payment_id on public.refunds(payment_id);

create index if not exists idx_seller_ledger_seller_id on public.seller_ledger(seller_id);
create index if not exists idx_seller_payouts_seller_id on public.seller_payouts(seller_id);
create index if not exists idx_sellers_user_id on public.sellers(user_id);
create index if not exists idx_shops_seller_id on public.shops(seller_id);
create index if not exists idx_products_shop_id on public.products(shop_id);
create index if not exists idx_products_category_id on public.products(category_id);

create index if not exists idx_messages_conversation_id on public.messages(conversation_id);
create index if not exists idx_conversation_members_conversation_id on public.conversation_members(conversation_id);
create index if not exists idx_conversation_members_user_id on public.conversation_members(user_id);

create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notification_devices_user_id on public.notification_devices(user_id);
create index if not exists idx_notification_preferences_user_id on public.notification_preferences(user_id);

create index if not exists idx_delivery_assignments_package_id on public.delivery_assignments(package_id);
create index if not exists idx_delivery_assignments_courier_id on public.delivery_assignments(courier_id);
create index if not exists idx_delivery_events_package_id on public.delivery_events(package_id);
create index if not exists idx_courier_locations_courier_id on public.courier_locations(courier_id);

create index if not exists idx_mechanic_requests_customer_id on public.mechanic_requests(customer_id);
create index if not exists idx_mechanic_quotes_request_id on public.mechanic_quotes(request_id);
create index if not exists idx_mechanic_quotes_mechanic_id on public.mechanic_quotes(mechanic_id);
create index if not exists idx_mechanic_assignments_request_id on public.mechanic_assignments(request_id);
create index if not exists idx_mechanic_assignments_mechanic_id on public.mechanic_assignments(mechanic_id);
create index if not exists idx_mechanic_interventions_request_id on public.mechanic_interventions(request_id);
create index if not exists idx_mechanic_interventions_quote_id on public.mechanic_interventions(quote_id);
create index if not exists idx_mechanic_interventions_mechanic_id on public.mechanic_interventions(mechanic_id);
create index if not exists idx_mechanic_availability_mechanic_id on public.mechanic_availability(mechanic_id);

create index if not exists idx_transport_bookings_customer_id on public.transport_bookings(customer_id);
create index if not exists idx_transport_bookings_trip_id on public.transport_bookings(trip_id);
create index if not exists idx_transport_tickets_booking_id on public.transport_tickets(booking_id);
create index if not exists idx_transport_trips_route_id on public.transport_trips(route_id);
create index if not exists idx_transport_trips_vehicle_id on public.transport_trips(vehicle_id);
create index if not exists idx_transport_routes_company_id on public.transport_routes(company_id);
create index if not exists idx_transport_routes_departure_station_id on public.transport_routes(departure_station_id);
create index if not exists idx_transport_routes_arrival_station_id on public.transport_routes(arrival_station_id);
create index if not exists idx_transport_vehicles_company_id on public.transport_vehicles(company_id);

create index if not exists idx_vehicle_rental_bookings_customer_id on public.vehicle_rental_bookings(customer_id);
create index if not exists idx_vehicle_rental_bookings_rental_id on public.vehicle_rental_bookings(rental_id);

create index if not exists idx_reviews_product_id on public.reviews(product_id);
create index if not exists idx_reviews_shop_id on public.reviews(shop_id);

commit;