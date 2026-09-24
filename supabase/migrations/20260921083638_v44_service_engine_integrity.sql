
alter table public.availability_schedules add constraint availability_weekday_valid check (weekday between 0 and 6);
alter table public.availability_schedules add constraint availability_time_range check (end_time>start_time);
alter table public.provider_time_off add constraint provider_time_off_range check (ends_at>starts_at);
alter table public.service_quotes add constraint service_quote_amount_nonnegative check (amount>=0);
alter table public.service_bookings add constraint service_booking_amount_nonnegative check (total_amount is null or total_amount>=0);
alter table public.service_requests add constraint service_request_latitude_valid check (latitude is null or latitude between -90 and 90);
alter table public.service_requests add constraint service_request_longitude_valid check (longitude is null or longitude between -180 and 180);
alter table public.services add constraint service_price_nonnegative check (price is null or price>=0);

create index if not exists idx_service_requests_customer_created on public.service_requests(customer_id,created_at desc);
create index if not exists idx_service_quotes_request_created on public.service_quotes(request_id,created_at desc);
create index if not exists idx_service_bookings_customer_created on public.service_bookings(customer_id,created_at desc);
create index if not exists idx_provider_locations_provider_recorded on public.provider_locations(provider_id,recorded_at desc);
create index if not exists idx_provider_time_off_provider_range on public.provider_time_off(provider_id,starts_at,ends_at);
