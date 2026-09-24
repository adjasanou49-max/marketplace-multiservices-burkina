
create table if not exists public.delivery_zones (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 active boolean not null default true,
 base_fee numeric(14,2) not null default 0 check(base_fee>=0),
 per_km_fee numeric(14,2) not null default 0 check(per_km_fee>=0),
 created_at timestamptz not null default now()
);
create table if not exists public.delivery_addresses (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references auth.users(id),
 label text,
 recipient_name text not null,
 phone text,
 address_line text,
 city text,
 latitude double precision,
 longitude double precision,
 is_default boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.delivery_pricing_rules (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 min_distance_km numeric(10,2) not null default 0 check(min_distance_km>=0),
 max_distance_km numeric(10,2),
 base_fee numeric(14,2) not null default 0 check(base_fee>=0),
 per_km_fee numeric(14,2) not null default 0 check(per_km_fee>=0),
 per_stop_fee numeric(14,2) not null default 0 check(per_stop_fee>=0),
 weight_fee numeric(14,2) not null default 0 check(weight_fee>=0),
 active boolean not null default true
);
create table if not exists public.delivery_route_quotes (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id),
 route_id uuid references public.delivery_routes(id),
 customer_fee numeric(14,2) not null check(customer_fee>=0),
 courier_compensation numeric(14,2) not null check(courier_compensation>=0),
 platform_subsidy numeric(14,2) not null default 0 check(platform_subsidy>=0),
 distance_km numeric(10,2),
 stop_count integer not null default 1 check(stop_count>0),
 created_at timestamptz not null default now()
);
create table if not exists public.delivery_assignment_events (
 id uuid primary key default gen_random_uuid(),
 assignment_id uuid not null references public.delivery_assignments(id) on delete cascade,
 actor_id uuid references auth.users(id),
 event_type text not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists idx_delivery_addresses_customer on public.delivery_addresses(customer_id);
create index if not exists idx_delivery_quotes_order on public.delivery_route_quotes(order_id);
create index if not exists idx_delivery_assignment_events_assignment on public.delivery_assignment_events(assignment_id,created_at);

alter table public.delivery_zones enable row level security;
alter table public.delivery_addresses enable row level security;
alter table public.delivery_pricing_rules enable row level security;
alter table public.delivery_route_quotes enable row level security;
alter table public.delivery_assignment_events enable row level security;

create policy delivery_zones_public_read on public.delivery_zones for select to anon,authenticated using(active=true);
create policy delivery_addresses_own on public.delivery_addresses for all to authenticated using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy delivery_pricing_public_read on public.delivery_pricing_rules for select to anon,authenticated using(active=true);
create policy delivery_quotes_customer_read on public.delivery_route_quotes for select to authenticated using(order_id in(select id from public.orders where customer_id=auth.uid()));
create policy delivery_assignment_events_customer_read on public.delivery_assignment_events for select to authenticated using(assignment_id in(select da.id from public.delivery_assignments da join public.order_packages op on op.id=da.package_id join public.order_groups og on og.id=op.order_group_id join public.orders o on o.id=og.order_id where o.customer_id=auth.uid()));
