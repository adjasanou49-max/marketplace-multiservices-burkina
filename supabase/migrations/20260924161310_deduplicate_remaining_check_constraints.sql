begin;

alter table public.availability_schedules drop constraint if exists availability_schedules_weekday_check;
alter table public.availability_schedules drop constraint if exists availability_schedules_check;

alter table public.coupons drop constraint if exists coupons_max_uses_check;
alter table public.coupons drop constraint if exists coupons_check;

alter table public.group_buy_members drop constraint if exists group_buy_members_quantity_check;
alter table public.group_buys drop constraint if exists group_buys_check;
alter table public.group_buys drop constraint if exists group_buys_group_price_check;

alter table public.promotions drop constraint if exists promotions_check;
alter table public.promotions drop constraint if exists promotions_value_check;

alter table public.provider_time_off drop constraint if exists provider_time_off_check;

alter table public.restaurant_menu_items drop constraint if exists restaurant_menu_items_price_check;
alter table public.restaurant_menu_items drop constraint if exists restaurant_menu_price_nonnegative;

alter table public.reviews drop constraint if exists reviews_rating_check;

alter table public.service_quotes drop constraint if exists service_quotes_amount_check;
alter table public.service_quotes drop constraint if exists service_quotes_amount_nonnegative;

alter table public.transport_trips drop constraint if exists transport_trips_price_check;
alter table public.transport_trips drop constraint if exists transport_trips_price_nonnegative;

commit;