begin;

alter table public.cart_items drop constraint if exists cart_items_quantity_check;
alter table public.cart_items drop constraint if exists cart_items_unit_price_check;

alter table public.commissions drop constraint if exists commissions_base_amount_check;
alter table public.commissions drop constraint if exists commissions_commission_amount_check;
alter table public.commissions drop constraint if exists commissions_rate_check;
alter table public.commissions drop constraint if exists commissions_rate_range;

alter table public.inventory drop constraint if exists inventory_quantity_check;
alter table public.inventory drop constraint if exists inventory_reserved_quantity_check;
alter table public.inventory drop constraint if exists inventory_reserved_not_above_quantity;

alter table public.order_items drop constraint if exists order_items_quantity_check;
alter table public.order_items drop constraint if exists order_items_total_price_check;
alter table public.order_items drop constraint if exists order_items_unit_price_check;

alter table public.payments drop constraint if exists payments_amount_check;

alter table public.refunds drop constraint if exists refunds_amount_check;

alter table public.seller_payouts drop constraint if exists seller_payouts_amount_check;
alter table public.seller_payouts drop constraint if exists seller_payouts_amount_nonnegative;

alter table public.transport_bookings drop constraint if exists transport_bookings_quantity_check;
alter table public.transport_bookings drop constraint if exists transport_bookings_total_amount_check;

commit;