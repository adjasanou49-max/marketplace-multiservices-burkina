
drop policy if exists courier_locations_courier_read on public.courier_locations;
drop policy if exists courier_locations_customer_read on public.courier_locations;

create policy courier_locations_read
on public.courier_locations
for select
to authenticated
using (
  courier_id = (select auth.uid())
  or exists (
    select 1
    from public.delivery_assignments da
    join public.order_packages op on op.id = da.package_id
    join public.order_groups og on og.id = op.order_group_id
    join public.orders o on o.id = og.order_id
    where da.courier_id = courier_locations.courier_id
      and o.customer_id = (select auth.uid())
      and op.delivered_at is null
  )
);

revoke execute on function public.apply_checkout_delivery_fee() from anon, authenticated, public;
revoke execute on function public.calculate_delivery_fee(uuid, jsonb) from anon, public;
grant execute on function public.calculate_delivery_fee(uuid, jsonb) to authenticated;

revoke execute on function public.st_estimatedextent(text, text) from anon, authenticated, public;
revoke execute on function public.st_estimatedextent(text, text, text) from anon, authenticated, public;
revoke execute on function public.st_estimatedextent(text, text, text, boolean) from anon, authenticated, public;
