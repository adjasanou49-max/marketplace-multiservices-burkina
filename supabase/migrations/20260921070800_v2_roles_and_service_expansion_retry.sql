
alter type public.user_role add value if not exists 'SERVICE_PROVIDER';
alter type public.user_role add value if not exists 'MECHANIC';
alter type public.user_role add value if not exists 'TRANSPORT_COMPANY';
alter type public.user_role add value if not exists 'ADMIN';
alter type public.user_role add value if not exists 'FINANCE';
alter type public.user_role add value if not exists 'SUPPORT';

create table if not exists public.availability_schedules (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id) on delete cascade,
 weekday smallint not null check(weekday between 0 and 6),
 start_time time not null,
 end_time time not null,
 active boolean not null default true,
 check(end_time > start_time)
);
create table if not exists public.provider_time_off (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id) on delete cascade,
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 reason text,
 check(ends_at > starts_at)
);
create table if not exists public.service_bookings (
 id uuid primary key default gen_random_uuid(),
 service_id uuid not null references public.services(id),
 customer_id uuid not null references auth.users(id),
 scheduled_at timestamptz not null,
 status text not null default 'REQUESTED' check(status in('REQUESTED','CONFIRMED','IN_PROGRESS','COMPLETED','CANCELLED','NO_SHOW')),
 total_amount numeric(14,2),
 created_at timestamptz not null default now()
);
create table if not exists public.provider_locations (
 id bigint generated always as identity primary key,
 provider_id uuid not null references public.service_providers(id),
 location public.geography(Point,4326) not null,
 accuracy_m numeric(8,2),
 recorded_at timestamptz not null default now()
);
create index if not exists idx_provider_locations_recent on public.provider_locations(provider_id,recorded_at desc);
create index if not exists idx_service_bookings_customer on public.service_bookings(customer_id,scheduled_at);

alter table public.availability_schedules enable row level security;
alter table public.provider_time_off enable row level security;
alter table public.service_bookings enable row level security;
alter table public.provider_locations enable row level security;

create policy availability_public_read on public.availability_schedules for select to anon,authenticated using(active=true);
create policy timeoff_public_none on public.provider_time_off for select to authenticated using(false);
create policy booking_customer_own on public.service_bookings for all to authenticated using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy provider_location_own_insert on public.provider_locations for insert to authenticated with check(provider_id in(select id from public.service_providers where user_id=auth.uid()));
create policy provider_location_own_read on public.provider_locations for select to authenticated using(provider_id in(select id from public.service_providers where user_id=auth.uid()));
