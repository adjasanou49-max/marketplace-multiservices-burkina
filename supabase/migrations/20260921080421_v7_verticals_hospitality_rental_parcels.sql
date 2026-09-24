
create table if not exists public.accommodations (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid references public.service_providers(id),
 name text not null,
 accommodation_type text not null check(accommodation_type in('HOTEL','HOSTEL','APARTMENT','GUESTHOUSE','ROOM')),
 description text,
 address text,
 latitude double precision,
 longitude double precision,
 active boolean not null default true,
 verification_status public.verification_status not null default 'PENDING',
 created_at timestamptz not null default now()
);
create table if not exists public.accommodation_units (
 id uuid primary key default gen_random_uuid(),
 accommodation_id uuid not null references public.accommodations(id) on delete cascade,
 name text not null,
 capacity integer not null check(capacity>0),
 price_per_night numeric(14,2) not null check(price_per_night>=0),
 quantity integer not null default 1 check(quantity>0),
 active boolean not null default true
);
create table if not exists public.accommodation_bookings (
 id uuid primary key default gen_random_uuid(),
 unit_id uuid not null references public.accommodation_units(id),
 customer_id uuid not null references auth.users(id),
 check_in date not null,
 check_out date not null,
 guests integer not null check(guests>0),
 status text not null default 'REQUESTED' check(status in('REQUESTED','CONFIRMED','CHECKED_IN','CHECKED_OUT','CANCELLED','NO_SHOW')),
 total_amount numeric(14,2) not null check(total_amount>=0),
 created_at timestamptz not null default now(),
 check(check_out>check_in)
);
create table if not exists public.vehicle_rentals (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid references public.service_providers(id),
 vehicle_type text not null,
 brand text,
 model text,
 registration text,
 daily_price numeric(14,2) not null check(daily_price>=0),
 deposit_amount numeric(14,2) not null default 0 check(deposit_amount>=0),
 active boolean not null default true,
 verification_status public.verification_status not null default 'PENDING'
);
create table if not exists public.vehicle_rental_bookings (
 id uuid primary key default gen_random_uuid(),
 rental_id uuid not null references public.vehicle_rentals(id),
 customer_id uuid not null references auth.users(id),
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 status text not null default 'REQUESTED' check(status in('REQUESTED','CONFIRMED','ACTIVE','COMPLETED','CANCELLED')),
 total_amount numeric(14,2) not null check(total_amount>=0),
 check(ends_at>starts_at)
);
create table if not exists public.parcels (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id),
 recipient_name text not null,
 recipient_phone text,
 pickup_address jsonb not null,
 delivery_address jsonb not null,
 weight_kg numeric(10,3) check(weight_kg>=0),
 status text not null default 'CREATED' check(status in('CREATED','READY','PICKED_UP','IN_TRANSIT','DELIVERED','RETURNED','DAMAGED','LOST','CANCELLED')),
 tracking_code text not null unique,
 created_at timestamptz not null default now()
);
create table if not exists public.parcel_events (
 id bigint generated always as identity primary key,
 parcel_id uuid not null references public.parcels(id) on delete cascade,
 actor_id uuid references auth.users(id),
 status text not null,
 latitude double precision,
 longitude double precision,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.pickup_points (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 address text,
 latitude double precision,
 longitude double precision,
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.parcel_pickup_points (
 parcel_id uuid not null references public.parcels(id) on delete cascade,
 pickup_point_id uuid not null references public.pickup_points(id),
 pickup_code_hash text,
 ready_at timestamptz,
 collected_at timestamptz,
 primary key(parcel_id,pickup_point_id)
);

alter table public.accommodations enable row level security;
alter table public.accommodation_units enable row level security;
alter table public.accommodation_bookings enable row level security;
alter table public.vehicle_rentals enable row level security;
alter table public.vehicle_rental_bookings enable row level security;
alter table public.parcels enable row level security;
alter table public.parcel_events enable row level security;
alter table public.pickup_points enable row level security;
alter table public.parcel_pickup_points enable row level security;

create policy accommodations_public on public.accommodations for select to anon,authenticated using(active=true and verification_status='VERIFIED');
create policy accommodation_units_public on public.accommodation_units for select to anon,authenticated using(active=true);
create policy accommodation_bookings_own on public.accommodation_bookings for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy vehicle_rentals_public on public.vehicle_rentals for select to anon,authenticated using(active=true and verification_status='VERIFIED');
create policy vehicle_rental_bookings_own on public.vehicle_rental_bookings for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy parcels_sender_own on public.parcels for all to authenticated using(sender_id=(select auth.uid())) with check(sender_id=(select auth.uid()));
create policy parcel_events_sender_read on public.parcel_events for select to authenticated using(parcel_id in(select id from public.parcels where sender_id=(select auth.uid())));
create policy pickup_points_public on public.pickup_points for select to anon,authenticated using(active=true);
create policy parcel_pickup_sender_read on public.parcel_pickup_points for select to authenticated using(parcel_id in(select id from public.parcels where sender_id=(select auth.uid())));

create index if not exists idx_accommodation_units_accommodation on public.accommodation_units(accommodation_id);
create index if not exists idx_accommodation_bookings_unit_dates on public.accommodation_bookings(unit_id,check_in,check_out);
create index if not exists idx_vehicle_rental_bookings_rental_dates on public.vehicle_rental_bookings(rental_id,starts_at,ends_at);
create index if not exists idx_parcels_sender_status on public.parcels(sender_id,status);
create index if not exists idx_parcel_events_parcel_time on public.parcel_events(parcel_id,created_at desc);
