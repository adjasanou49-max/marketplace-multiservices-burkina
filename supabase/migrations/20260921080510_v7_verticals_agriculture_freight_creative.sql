
create table if not exists public.agriculture_listings (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid references public.sellers(id),
 listing_type text not null check(listing_type in('PRODUCE','LIVESTOCK','SEEDS','EQUIPMENT','INPUTS')),
 name text not null,
 description text,
 price numeric(14,2) check(price>=0),
 unit text,
 quantity numeric(14,3) check(quantity>=0),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.freight_requests (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id),
 pickup jsonb not null,
 delivery jsonb not null,
 weight_kg numeric(12,3) check(weight_kg>=0),
 volume_m3 numeric(12,4) check(volume_m3>=0),
 description text,
 status text not null default 'OPEN' check(status in('OPEN','QUOTED','ASSIGNED','IN_TRANSIT','DELIVERED','CANCELLED')),
 created_at timestamptz not null default now()
);
create table if not exists public.freight_quotes (
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null references public.freight_requests(id) on delete cascade,
 provider_id uuid not null references public.service_providers(id),
 amount numeric(14,2) not null check(amount>=0),
 status text not null default 'PROPOSED' check(status in('PROPOSED','ACCEPTED','REJECTED','EXPIRED')),
 created_at timestamptz not null default now()
);
create table if not exists public.creative_services (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id),
 category text not null,
 name text not null,
 description text,
 starting_price numeric(14,2) check(starting_price>=0),
 active boolean not null default true
);
create table if not exists public.creative_bookings (
 id uuid primary key default gen_random_uuid(),
 service_id uuid not null references public.creative_services(id),
 customer_id uuid not null references auth.users(id),
 scheduled_at timestamptz,
 status text not null default 'REQUESTED' check(status in('REQUESTED','CONFIRMED','IN_PROGRESS','COMPLETED','CANCELLED')),
 agreed_amount numeric(14,2) check(agreed_amount>=0)
);
create table if not exists public.ride_requests (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id),
 pickup jsonb not null,
 destination jsonb not null,
 status text not null default 'REQUESTED' check(status in('REQUESTED','MATCHING','ASSIGNED','DRIVER_ARRIVING','IN_RIDE','COMPLETED','CANCELLED')),
 fare_estimate numeric(14,2) check(fare_estimate>=0),
 created_at timestamptz not null default now()
);
create table if not exists public.ride_assignments (
 id uuid primary key default gen_random_uuid(),
 ride_request_id uuid not null references public.ride_requests(id) on delete cascade,
 provider_id uuid not null references public.service_providers(id),
 status text not null default 'OFFERED' check(status in('OFFERED','ACCEPTED','REJECTED','COMPLETED')),
 created_at timestamptz not null default now()
);
alter table public.agriculture_listings enable row level security;
alter table public.freight_requests enable row level security;
alter table public.freight_quotes enable row level security;
alter table public.creative_services enable row level security;
alter table public.creative_bookings enable row level security;
alter table public.ride_requests enable row level security;
alter table public.ride_assignments enable row level security;
create policy agriculture_public on public.agriculture_listings for select to anon,authenticated using(active=true);
create policy freight_requests_own on public.freight_requests for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy freight_quotes_customer on public.freight_quotes for select to authenticated using(request_id in(select id from public.freight_requests where customer_id=(select auth.uid())));
create policy creative_public on public.creative_services for select to anon,authenticated using(active=true);
create policy creative_bookings_own on public.creative_bookings for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy ride_requests_own on public.ride_requests for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy ride_assignments_customer on public.ride_assignments for select to authenticated using(ride_request_id in(select id from public.ride_requests where customer_id=(select auth.uid())));
