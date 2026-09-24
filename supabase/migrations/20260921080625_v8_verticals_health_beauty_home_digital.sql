
create table if not exists public.health_providers (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null unique references public.service_providers(id) on delete cascade,
 provider_type text not null check(provider_type in('PHARMACY','CLINIC','LAB','OTHER')),
 license_reference text,
 verified boolean not null default false,
 active boolean not null default true
);
create table if not exists public.health_products (
 id uuid primary key default gen_random_uuid(),
 health_provider_id uuid not null references public.health_providers(id) on delete cascade,
 name text not null,
 description text,
 price numeric(14,2) check(price>=0),
 requires_prescription boolean not null default false,
 stock_quantity integer not null default 0 check(stock_quantity>=0),
 active boolean not null default true
);
create table if not exists public.beauty_services (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id),
 name text not null,
 description text,
 duration_minutes integer check(duration_minutes>0),
 price numeric(14,2) check(price>=0),
 active boolean not null default true
);
create table if not exists public.beauty_bookings (
 id uuid primary key default gen_random_uuid(),
 service_id uuid not null references public.beauty_services(id),
 customer_id uuid not null references auth.users(id),
 scheduled_at timestamptz not null,
 status text not null default 'REQUESTED' check(status in('REQUESTED','CONFIRMED','COMPLETED','CANCELLED','NO_SHOW')),
 amount numeric(14,2) check(amount>=0)
);
create table if not exists public.home_services (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id),
 service_type text not null,
 name text not null,
 description text,
 starting_price numeric(14,2) check(starting_price>=0),
 active boolean not null default true
);
create table if not exists public.home_service_requests (
 id uuid primary key default gen_random_uuid(),
 service_id uuid not null references public.home_services(id),
 customer_id uuid not null references auth.users(id),
 scheduled_at timestamptz,
 address jsonb not null,
 status text not null default 'REQUESTED' check(status in('REQUESTED','QUOTED','ACCEPTED','ON_SITE','IN_PROGRESS','COMPLETED','CANCELLED')),
 agreed_amount numeric(14,2) check(agreed_amount>=0),
 created_at timestamptz not null default now()
);
create table if not exists public.digital_services (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id),
 category text not null,
 name text not null,
 description text,
 price numeric(14,2) check(price>=0),
 active boolean not null default true
);
create table if not exists public.digital_orders (
 id uuid primary key default gen_random_uuid(),
 digital_service_id uuid not null references public.digital_services(id),
 customer_id uuid not null references auth.users(id),
 status text not null default 'REQUESTED' check(status in('REQUESTED','PAID','IN_PROGRESS','DELIVERED','CANCELLED','REFUNDED')),
 amount numeric(14,2) not null check(amount>=0),
 deliverable_path text,
 created_at timestamptz not null default now()
);
alter table public.health_providers enable row level security;
alter table public.health_products enable row level security;
alter table public.beauty_services enable row level security;
alter table public.beauty_bookings enable row level security;
alter table public.home_services enable row level security;
alter table public.home_service_requests enable row level security;
alter table public.digital_services enable row level security;
alter table public.digital_orders enable row level security;
create policy health_providers_public on public.health_providers for select to anon,authenticated using(active=true and verified=true);
create policy health_products_public on public.health_products for select to anon,authenticated using(active=true);
create policy beauty_services_public on public.beauty_services for select to anon,authenticated using(active=true);
create policy beauty_bookings_own on public.beauty_bookings for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy home_services_public on public.home_services for select to anon,authenticated using(active=true);
create policy home_service_requests_own on public.home_service_requests for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy digital_services_public on public.digital_services for select to anon,authenticated using(active=true);
create policy digital_orders_own on public.digital_orders for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
