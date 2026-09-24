
create policy delivery_pricing_admin_insert
on public.delivery_pricing_rules
for insert to authenticated
with check ((select private.is_admin()));

create policy delivery_pricing_admin_update
on public.delivery_pricing_rules
for update to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy delivery_pricing_admin_delete
on public.delivery_pricing_rules
for delete to authenticated
using ((select private.is_admin()));
