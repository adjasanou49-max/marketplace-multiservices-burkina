
alter table public.restaurant_menu_items add constraint restaurant_menu_price_nonnegative check (price>=0);
alter table public.restaurant_profiles add constraint restaurant_prep_time_positive check (preparation_time_min is null or preparation_time_min>=0);
alter table public.transport_bookings add constraint transport_booking_quantity_positive check (quantity>0);
alter table public.transport_bookings add constraint transport_booking_amount_nonnegative check (total_amount>=0);
alter table public.transport_trips add constraint transport_trip_price_nonnegative check (price>=0);
alter table public.mechanic_requests add constraint mechanic_latitude_valid check (latitude between -90 and 90);
alter table public.mechanic_requests add constraint mechanic_longitude_valid check (longitude between -180 and 180);
alter table public.mechanic_time_off add constraint mechanic_time_off_range check (ends_at>starts_at);
alter table public.mechanic_availability add constraint mechanic_availability_range check (ends_at is null or ends_at>starts_at);

create unique index if not exists uq_notification_device_token on public.notification_devices(push_token);
create index if not exists idx_notifications_user_unread on public.notifications(user_id,read_at,created_at desc);
create index if not exists idx_messages_conversation_created on public.messages(conversation_id,created_at desc);
create index if not exists idx_restaurant_menu_items_menu_sort on public.restaurant_menu_items(menu_id,sort_order);
create index if not exists idx_restaurant_events_group_created on public.restaurant_order_events(order_group_id,created_at desc);
create index if not exists idx_transport_bookings_customer_created on public.transport_bookings(customer_id,created_at desc);
create index if not exists idx_transport_tickets_booking on public.transport_tickets(booking_id);
create index if not exists idx_mechanic_requests_customer_created on public.mechanic_requests(customer_id,created_at desc);
