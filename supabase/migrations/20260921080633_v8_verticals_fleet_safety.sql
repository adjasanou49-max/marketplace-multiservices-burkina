
create table if not exists public.provider_vehicles (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id) on delete cascade,
 vehicle_type text not null,
 registration text,
 brand text,
 model text,
 active boolean not null default true
);
create table if not exists public.vehicle_inspections (
 id uuid primary key default gen_random_uuid(),
 vehicle_id uuid not null references public.provider_vehicles(id) on delete cascade,
 inspection_type text not null check(inspection_type in('BEFORE_RENTAL','AFTER_RENTAL','DELIVERY','INCIDENT')),
 mileage numeric(12,2),
 condition_notes text,
 media jsonb not null default '[]'::jsonb,
 inspected_at timestamptz not null default now()
);
create table if not exists public.safety_alerts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users(id),
 alert_type text not null,
 latitude double precision,
 longitude double precision,
 description text,
 status text not null default 'OPEN' check(status in('OPEN','ACKNOWLEDGED','RESOLVED','CANCELLED')),
 created_at timestamptz not null default now()
);
create table if not exists public.provider_incidents (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id),
 category text not null,
 description text not null,
 severity text not null default 'MEDIUM' check(severity in('LOW','MEDIUM','HIGH','CRITICAL')),
 status text not null default 'OPEN' check(status in('OPEN','INVESTIGATING','RESOLVED','CLOSED')),
 created_at timestamptz not null default now()
);
alter table public.provider_vehicles enable row level security;
alter table public.vehicle_inspections enable row level security;
alter table public.safety_alerts enable row level security;
alter table public.provider_incidents enable row level security;
create policy provider_vehicles_own on public.provider_vehicles for all to authenticated using(provider_id in(select id from public.service_providers where user_id=(select auth.uid()))) with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));
create policy vehicle_inspections_provider on public.vehicle_inspections for select to authenticated using(vehicle_id in(select id from public.provider_vehicles where provider_id in(select id from public.service_providers where user_id=(select auth.uid()))));
create policy safety_alerts_own on public.safety_alerts for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy provider_incidents_own on public.provider_incidents for all to authenticated using(provider_id in(select id from public.service_providers where user_id=(select auth.uid()))) with check(provider_id in(select id from public.service_providers where user_id=(select auth.uid())));
