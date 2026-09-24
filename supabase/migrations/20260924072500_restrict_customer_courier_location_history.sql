alter policy courier_locations_read
on public.courier_locations
using (
  courier_id = auth.uid()
  or (
    id = (
      select cl.id
      from public.courier_locations cl
      order by cl.recorded_at desc, cl.id desc
      limit 1
    )
    and exists (
      select 1
      from public.delivery_assignments da
      join public.order_packages op on op.id = da.package_id
      join public.order_groups og on og.id = op.order_group_id
      join public.orders o on o.id = og.order_id
      where da.courier_id = courier_locations.courier_id
        and o.customer_id = auth.uid()
        and op.delivered_at is null
    )
  )
);
