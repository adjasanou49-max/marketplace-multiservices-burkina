alter table public.delivery_addresses
  add constraint delivery_addresses_latitude_range
  check (latitude is null or latitude between -90 and 90);

alter table public.delivery_addresses
  add constraint delivery_addresses_longitude_range
  check (longitude is null or longitude between -180 and 180);
