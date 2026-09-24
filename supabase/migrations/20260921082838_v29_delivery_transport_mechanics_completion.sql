
create table if not exists public.delivery_events(
 id uuid primary key default gen_random_uuid(),
 package_id uuid not null references public.order_packages(id) on delete cascade,
 actor_id uuid references auth.users(id),
 status public.delivery_status not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.delivery_events enable row level security;

create table if not exists public.courier_earnings(
 id uuid primary key default gen_random_uuid(),
 courier_id uuid not null references auth.users(id),
 delivery_assignment_id uuid references public.delivery_assignments(id),
 amount numeric not null,
 currency text not null default 'XOF',
 status text not null default 'PENDING',
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.courier_earnings enable row level security;

create table if not exists public.courier_incidents(
 id uuid primary key default gen_random_uuid(),
 courier_id uuid not null references auth.users(id),
 delivery_assignment_id uuid references public.delivery_assignments(id),
 package_id uuid references public.order_packages(id),
 category text not null,
 description text not null,
 severity text not null default 'MEDIUM',
 status text not null default 'OPEN',
 created_at timestamptz not null default now()
);
alter table public.courier_incidents enable row level security;

create table if not exists public.transport_drivers(
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.transport_companies(id) on delete cascade,
 user_id uuid references auth.users(id),
 first_name text not null,
 last_name text,
 phone text,
 license_number text,
 active boolean not null default true,
 created_at timestamptz not null default now()
);
alter table public.transport_drivers enable row level security;

create table if not exists public.transport_trip_stops(
 id uuid primary key default gen_random_uuid(),
 trip_id uuid not null references public.transport_trips(id) on delete cascade,
 station_id uuid not null references public.transport_stations(id),
 stop_order integer not null,
 arrival_at timestamptz,
 departure_at timestamptz,
 unique(trip_id,stop_order)
);
alter table public.transport_trip_stops enable row level security;

create table if not exists public.transport_seats(
 id uuid primary key default gen_random_uuid(),
 vehicle_id uuid not null references public.transport_vehicles(id) on delete cascade,
 seat_number text not null,
 row_number integer,
 column_number integer,
 active boolean not null default true,
 unique(vehicle_id,seat_number)
);
alter table public.transport_seats enable row level security;

create table if not exists public.transport_checkins(
 id uuid primary key default gen_random_uuid(),
 ticket_id uuid not null references public.transport_tickets(id) on delete cascade,
 checked_by uuid references auth.users(id),
 checked_at timestamptz not null default now(),
 method text not null default 'QR'
);
alter table public.transport_checkins enable row level security;

create table if not exists public.transport_boarding_events(
 id uuid primary key default gen_random_uuid(),
 ticket_id uuid not null references public.transport_tickets(id) on delete cascade,
 actor_id uuid references auth.users(id),
 event_type text not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.transport_boarding_events enable row level security;

create table if not exists public.mechanic_quotes(
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null references public.mechanic_requests(id) on delete cascade,
 mechanic_id uuid not null references public.mechanics(id),
 amount numeric not null,
 currency text not null default 'XOF',
 diagnosis text,
 status text not null default 'PENDING',
 expires_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.mechanic_quotes enable row level security;

create table if not exists public.mechanic_interventions(
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null references public.mechanic_requests(id) on delete cascade,
 mechanic_id uuid not null references public.mechanics(id),
 quote_id uuid references public.mechanic_quotes(id),
 status text not null default 'ACCEPTED',
 started_at timestamptz,
 arrived_at timestamptz,
 completed_at timestamptz,
 final_amount numeric,
 currency text not null default 'XOF',
 created_at timestamptz not null default now()
);
alter table public.mechanic_interventions enable row level security;

create table if not exists public.mechanic_intervention_events(
 id uuid primary key default gen_random_uuid(),
 intervention_id uuid not null references public.mechanic_interventions(id) on delete cascade,
 actor_id uuid references auth.users(id),
 event_type text not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.mechanic_intervention_events enable row level security;

create table if not exists public.mechanic_reviews(
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null references public.mechanic_requests(id) on delete cascade,
 customer_id uuid not null references auth.users(id),
 mechanic_id uuid not null references public.mechanics(id),
 rating integer not null check(rating between 1 and 5),
 body text,
 created_at timestamptz not null default now(),
 unique(request_id,customer_id)
);
alter table public.mechanic_reviews enable row level security;

create table if not exists public.mechanic_incidents(
 id uuid primary key default gen_random_uuid(),
 request_id uuid references public.mechanic_requests(id),
 mechanic_id uuid references public.mechanics(id),
 reporter_id uuid references auth.users(id),
 category text not null,
 description text not null,
 severity text not null default 'MEDIUM',
 status text not null default 'OPEN',
 created_at timestamptz not null default now()
);
alter table public.mechanic_incidents enable row level security;

create index if not exists idx_delivery_events_package_created on public.delivery_events(package_id,created_at desc);
create index if not exists idx_courier_earnings_courier_created on public.courier_earnings(courier_id,created_at desc);
create index if not exists idx_courier_incidents_courier_created on public.courier_incidents(courier_id,created_at desc);
create index if not exists idx_transport_drivers_company on public.transport_drivers(company_id);
create index if not exists idx_transport_trip_stops_trip on public.transport_trip_stops(trip_id,stop_order);
create index if not exists idx_transport_checkins_ticket on public.transport_checkins(ticket_id,checked_at desc);
create index if not exists idx_mechanic_quotes_request on public.mechanic_quotes(request_id,created_at desc);
create index if not exists idx_mechanic_interventions_request on public.mechanic_interventions(request_id);
