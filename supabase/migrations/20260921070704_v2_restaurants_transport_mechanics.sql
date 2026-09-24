
create table if not exists public.restaurant_profiles (
 id uuid primary key default gen_random_uuid(),
 shop_id uuid not null unique references public.shops(id),
 cuisine_types text[] not null default '{}',
 preparation_time_min integer,
 delivery_available boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.restaurant_menus (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurant_profiles(id) on delete cascade,
 name text not null,
 description text,
 active boolean not null default true,
 sort_order integer not null default 0
);
create table if not exists public.restaurant_menu_items (
 id uuid primary key default gen_random_uuid(),
 menu_id uuid not null references public.restaurant_menus(id) on delete cascade,
 product_id uuid references public.products(id),
 name text not null,
 description text,
 price numeric(14,2) not null check(price>=0),
 active boolean not null default true,
 sort_order integer not null default 0
);
create table if not exists public.restaurant_order_events (
 id uuid primary key default gen_random_uuid(),
 order_group_id uuid not null references public.order_groups(id) on delete cascade,
 status text not null check(status in ('RECEIVED','CONFIRMED','PREPARING','READY','COURIER_PICKUP','IN_DELIVERY','DELIVERED','CANCELLED')),
 created_at timestamptz not null default now()
);
create table if not exists public.transport_companies (
 id uuid primary key default gen_random_uuid(),
 owner_user_id uuid not null references auth.users(id),
 name text not null unique,
 phone text,
 verification_status public.verification_status not null default 'PENDING',
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.transport_stations (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.transport_companies(id) on delete cascade,
 name text not null,
 address text,
 latitude double precision,
 longitude double precision
);
create table if not exists public.transport_routes (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.transport_companies(id) on delete cascade,
 departure_station_id uuid not null references public.transport_stations(id),
 arrival_station_id uuid not null references public.transport_stations(id),
 duration_minutes integer,
 base_price numeric(14,2) not null check(base_price>=0),
 active boolean not null default true
);
create table if not exists public.transport_vehicles (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.transport_companies(id) on delete cascade,
 registration text not null,
 seat_count integer not null check(seat_count>0),
 active boolean not null default true,
 unique(company_id,registration)
);
create table if not exists public.transport_trips (
 id uuid primary key default gen_random_uuid(),
 route_id uuid not null references public.transport_routes(id),
 vehicle_id uuid references public.transport_vehicles(id),
 departure_at timestamptz not null,
 arrival_at timestamptz,
 price numeric(14,2) not null check(price>=0),
 status text not null default 'SCHEDULED' check(status in('SCHEDULED','BOARDING','DEPARTED','ARRIVED','CANCELLED'))
);
create table if not exists public.transport_bookings (
 id uuid primary key default gen_random_uuid(),
 trip_id uuid not null references public.transport_trips(id),
 customer_id uuid not null references auth.users(id),
 quantity integer not null check(quantity>0),
 total_amount numeric(14,2) not null check(total_amount>=0),
 status text not null default 'RESERVED' check(status in('RESERVED','PAID','ISSUED','CHECKED_IN','BOARDED','USED','CANCELLED','REFUNDED','EXPIRED')),
 qr_token_hash text,
 created_at timestamptz not null default now()
);
create table if not exists public.transport_tickets (
 id uuid primary key default gen_random_uuid(),
 booking_id uuid not null references public.transport_bookings(id) on delete cascade,
 passenger_name text not null,
 seat_number text,
 status text not null default 'ISSUED' check(status in('ISSUED','CHECKED_IN','BOARDED','USED','CANCELLED','EXPIRED')),
 created_at timestamptz not null default now()
);
create table if not exists public.mechanics (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null unique references auth.users(id),
 display_name text not null,
 phone text,
 verification_status public.verification_status not null default 'PENDING',
 active boolean not null default true,
 service_radius_km numeric(8,2),
 created_at timestamptz not null default now()
);
create table if not exists public.mechanic_services (
 id uuid primary key default gen_random_uuid(),
 mechanic_id uuid not null references public.mechanics(id) on delete cascade,
 service_type text not null,
 vehicle_type text not null check(vehicle_type in('CAR','MOTORCYCLE','BICYCLE')),
 base_price numeric(14,2) check(base_price>=0),
 active boolean not null default true
);
create table if not exists public.mechanic_availability (
 id uuid primary key default gen_random_uuid(),
 mechanic_id uuid not null references public.mechanics(id) on delete cascade,
 status text not null check(status in('AVAILABLE','IN_10_MIN','IN_20_MIN','IN_30_MIN','UNAVAILABLE')),
 starts_at timestamptz not null,
 ends_at timestamptz
);
create table if not exists public.mechanic_time_off (
 id uuid primary key default gen_random_uuid(),
 mechanic_id uuid not null references public.mechanics(id) on delete cascade,
 reason text,
 starts_at timestamptz not null,
 ends_at timestamptz not null
);
create table if not exists public.mechanic_requests (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id),
 vehicle_type text not null check(vehicle_type in('CAR','MOTORCYCLE','BICYCLE')),
 problem_type text not null,
 description text,
 latitude double precision not null,
 longitude double precision not null,
 status text not null default 'OPEN' check(status in('OPEN','ACCEPTED','ON_ROUTE','ARRIVED','DIAGNOSING','REPAIRING','COMPLETED','CANCELLED')),
 created_at timestamptz not null default now()
);
create table if not exists public.mechanic_assignments (
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null references public.mechanic_requests(id) on delete cascade,
 mechanic_id uuid not null references public.mechanics(id),
 status text not null default 'ASSIGNED' check(status in('ASSIGNED','ACCEPTED','REJECTED','COMPLETED')),
 assigned_at timestamptz not null default now()
);
create index if not exists idx_transport_trips_departure on public.transport_trips(departure_at,status);
create index if not exists idx_transport_bookings_customer on public.transport_bookings(customer_id,status);
create index if not exists idx_mechanic_requests_customer on public.mechanic_requests(customer_id,status);
create index if not exists idx_mechanic_availability on public.mechanic_availability(mechanic_id,starts_at);

alter table public.restaurant_profiles enable row level security;
alter table public.restaurant_menus enable row level security;
alter table public.restaurant_menu_items enable row level security;
alter table public.restaurant_order_events enable row level security;
alter table public.transport_companies enable row level security;
alter table public.transport_stations enable row level security;
alter table public.transport_routes enable row level security;
alter table public.transport_vehicles enable row level security;
alter table public.transport_trips enable row level security;
alter table public.transport_bookings enable row level security;
alter table public.transport_tickets enable row level security;
alter table public.mechanics enable row level security;
alter table public.mechanic_services enable row level security;
alter table public.mechanic_availability enable row level security;
alter table public.mechanic_time_off enable row level security;
alter table public.mechanic_requests enable row level security;
alter table public.mechanic_assignments enable row level security;

create policy restaurant_public_profile on public.restaurant_profiles for select to anon,authenticated using(true);
create policy restaurant_public_menu on public.restaurant_menus for select to anon,authenticated using(active=true);
create policy restaurant_public_items on public.restaurant_menu_items for select to anon,authenticated using(active=true);
create policy restaurant_order_events_customer on public.restaurant_order_events for select to authenticated using(order_group_id in(select og.id from public.order_groups og join public.orders o on o.id=og.order_id where o.customer_id=auth.uid()));
create policy transport_public_companies on public.transport_companies for select to anon,authenticated using(active=true and verification_status='VERIFIED');
create policy transport_public_stations on public.transport_stations for select to anon,authenticated using(true);
create policy transport_public_routes on public.transport_routes for select to anon,authenticated using(active=true);
create policy transport_public_trips on public.transport_trips for select to anon,authenticated using(status in('SCHEDULED','BOARDING'));
create policy transport_booking_own on public.transport_bookings for all to authenticated using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy transport_ticket_own on public.transport_tickets for select to authenticated using(booking_id in(select id from public.transport_bookings where customer_id=auth.uid()));
create policy mechanics_public on public.mechanics for select to anon,authenticated using(active=true and verification_status='VERIFIED');
create policy mechanic_services_public on public.mechanic_services for select to anon,authenticated using(active=true);
create policy mechanic_availability_public on public.mechanic_availability for select to anon,authenticated using(true);
create policy mechanic_time_off_public on public.mechanic_time_off for select to authenticated using(false);
create policy mechanic_request_own on public.mechanic_requests for all to authenticated using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy mechanic_assignment_customer on public.mechanic_assignments for select to authenticated using(request_id in(select id from public.mechanic_requests where customer_id=auth.uid()));
