
-- Consolidate public + owner SELECT policies into one policy per table/action.
drop policy if exists products_owner_read on public.products;
drop policy if exists products_public_read on public.products;
create policy products_read on public.products
for select to anon,authenticated
using (
 status='ACTIVE' and (not is_expirable or expiry_date is null or expiry_date >= current_date)
 or shop_id in (select s.id from public.shops s join public.sellers se on se.id=s.seller_id where se.user_id=(select auth.uid()))
);

drop policy if exists shops_owner_read on public.shops;
drop policy if exists shops_public_read on public.shops;
create policy shops_read on public.shops
for select to anon,authenticated
using (
 (status='ACTIVE' and verification_status='VERIFIED')
 or seller_id in(select id from public.sellers where user_id=(select auth.uid()))
);

drop policy if exists reviews_owner_read on public.reviews;
drop policy if exists reviews_public_read on public.reviews;
create policy reviews_read on public.reviews
for select to anon,authenticated
using (
 status='PUBLISHED' or customer_id=(select auth.uid())
);

drop policy if exists service_provider_own_read on public.service_providers;
drop policy if exists providers_public_read on public.service_providers;
create policy providers_read on public.service_providers
for select to authenticated
using(active=true or user_id=(select auth.uid()));

drop policy if exists services_provider_manage on public.services;
drop policy if exists services_public_read on public.services;
create policy services_read on public.services
for select to authenticated
using(
 active=true
 or provider_id in(select id from public.service_providers where user_id=(select auth.uid()))
);
create policy services_provider_manage on public.services
for all to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())))
with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

drop policy if exists availability_provider_manage on public.availability_schedules;
drop policy if exists availability_public_read on public.availability_schedules;
create policy availability_read on public.availability_schedules
for select to authenticated
using(
 provider_id in(select id from public.service_providers where user_id=(select auth.uid()))
 or true
);

drop policy if exists timeoff_provider_manage on public.provider_time_off;
drop policy if exists timeoff_public_none on public.provider_time_off;
create policy timeoff_provider_manage on public.provider_time_off
for all to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())))
with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

drop policy if exists provider_location_own_read on public.provider_locations;
drop policy if exists provider_locations_provider_read on public.provider_locations;
create policy provider_locations_read on public.provider_locations
for select to authenticated
using(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));

drop policy if exists order_groups_customer_read on public.order_groups;
drop policy if exists order_groups_seller_read on public.order_groups;
create policy order_groups_read on public.order_groups
for select to authenticated
using(
 order_id in(select id from public.orders where customer_id=(select auth.uid()))
 or shop_id in(select s.id from public.shops s join public.sellers se on se.id=s.seller_id where se.user_id=(select auth.uid()))
);

drop policy if exists order_items_customer_read on public.order_items;
drop policy if exists order_items_seller_read on public.order_items;
create policy order_items_read on public.order_items
for select to authenticated
using(
 order_group_id in(select og.id from public.order_groups og join public.orders o on o.id=og.order_id where o.customer_id=(select auth.uid()))
 or order_group_id in(select og.id from public.order_groups og join public.shops s on s.id=og.shop_id join public.sellers se on se.id=s.seller_id where se.user_id=(select auth.uid()))
);

drop policy if exists order_packages_customer_read on public.order_packages;
drop policy if exists order_packages_seller_read on public.order_packages;
create policy order_packages_read on public.order_packages
for select to authenticated
using(
 order_group_id in(select og.id from public.order_groups og join public.orders o on o.id=og.order_id where o.customer_id=(select auth.uid()))
 or order_group_id in(select og.id from public.order_groups og join public.shops s on s.id=og.shop_id join public.sellers se on se.id=s.seller_id where se.user_id=(select auth.uid()))
);
