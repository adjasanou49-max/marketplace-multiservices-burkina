begin;

drop policy if exists accommodation_units_public on public.accommodation_units;
create policy accommodation_units_public
on public.accommodation_units
for select
to anon, authenticated
using (
  active = true
  and exists (
    select 1
    from public.accommodations a
    where a.id = accommodation_units.accommodation_id
      and a.active = true
      and a.verification_status = 'VERIFIED'
  )
);

drop policy if exists health_products_public on public.health_products;
create policy health_products_public
on public.health_products
for select
to anon, authenticated
using (
  active = true
  and exists (
    select 1
    from public.health_providers hp
    where hp.id = health_products.health_provider_id
      and hp.active = true
      and hp.verified = true
  )
);

drop policy if exists mechanic_availability_public on public.mechanic_availability;
create policy mechanic_availability_public
on public.mechanic_availability
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = mechanic_availability.mechanic_id
      and m.active = true
      and m.verification_status = 'VERIFIED'
  )
);

drop policy if exists mechanic_services_public on public.mechanic_services;
create policy mechanic_services_public
on public.mechanic_services
for select
to anon, authenticated
using (
  active = true
  and exists (
    select 1
    from public.mechanics m
    where m.id = mechanic_services.mechanic_id
      and m.active = true
      and m.verification_status = 'VERIFIED'
  )
);

drop policy if exists product_images_public_read on public.product_images;
create policy product_images_public_read
on public.product_images
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products p
    join public.shops s on s.id = p.shop_id
    where p.id = product_images.product_id
      and p.status = 'ACTIVE'
      and s.status = 'ACTIVE'
      and s.verification_status = 'VERIFIED'
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);

drop policy if exists product_variants_public_read on public.product_variants;
create policy product_variants_public_read
on public.product_variants
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products p
    join public.shops s on s.id = p.shop_id
    where p.id = product_variants.product_id
      and p.status = 'ACTIVE'
      and s.status = 'ACTIVE'
      and s.verification_status = 'VERIFIED'
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);

drop policy if exists product_attributes_public on public.product_attributes;
create policy product_attributes_public
on public.product_attributes
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products p
    join public.shops s on s.id = p.shop_id
    where p.id = product_attributes.product_id
      and p.status = 'ACTIVE'
      and s.status = 'ACTIVE'
      and s.verification_status = 'VERIFIED'
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);

drop policy if exists product_tags_public on public.product_tags;
create policy product_tags_public
on public.product_tags
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products p
    join public.shops s on s.id = p.shop_id
    where p.id = product_tags.product_id
      and p.status = 'ACTIVE'
      and s.status = 'ACTIVE'
      and s.verification_status = 'VERIFIED'
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);

drop policy if exists product_videos_public on public.product_videos;
create policy product_videos_public
on public.product_videos
for select
to anon, authenticated
using (
  active = true
  and exists (
    select 1
    from public.products p
    join public.shops s on s.id = p.shop_id
    where p.id = product_videos.product_id
      and p.status = 'ACTIVE'
      and s.status = 'ACTIVE'
      and s.verification_status = 'VERIFIED'
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);

drop policy if exists transport_public_routes on public.transport_routes;
create policy transport_public_routes
on public.transport_routes
for select
to anon, authenticated
using (
  active = true
  and exists (
    select 1
    from public.transport_companies tc
    where tc.id = transport_routes.company_id
      and tc.active = true
      and tc.verification_status = 'VERIFIED'
  )
);

drop policy if exists transport_public_trips on public.transport_trips;
create policy transport_public_trips
on public.transport_trips
for select
to anon, authenticated
using (
  status in ('SCHEDULED','BOARDING')
  and exists (
    select 1
    from public.transport_routes tr
    join public.transport_companies tc on tc.id = tr.company_id
    where tr.id = transport_trips.route_id
      and tr.active = true
      and tc.active = true
      and tc.verification_status = 'VERIFIED'
  )
);

drop policy if exists transport_vehicle_public_read on public.transport_vehicles;
create policy transport_vehicle_public_read
on public.transport_vehicles
for select
to anon, authenticated
using (
  active = true
  and exists (
    select 1
    from public.transport_companies tc
    where tc.id = transport_vehicles.company_id
      and tc.active = true
      and tc.verification_status = 'VERIFIED'
  )
);

revoke select on table public.transport_vehicles from anon, authenticated;
grant select (id, company_id, seat_count, active)
  on table public.transport_vehicles
  to anon, authenticated;

commit;