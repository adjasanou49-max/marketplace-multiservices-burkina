
create table if not exists public.real_estate_listings (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid references public.service_providers(id),
 listing_type text not null check(listing_type in('SALE','RENT','LAND','COMMERCIAL')),
 title text not null,
 description text,
 price numeric(16,2) not null check(price>=0),
 city text,
 address text,
 latitude double precision,
 longitude double precision,
 bedrooms integer,
 bathrooms integer,
 area_m2 numeric(12,2),
 active boolean not null default true,
 verification_status public.verification_status not null default 'PENDING',
 created_at timestamptz not null default now()
);
create table if not exists public.events (
 id uuid primary key default gen_random_uuid(),
 organizer_id uuid references public.service_providers(id),
 title text not null,
 description text,
 venue text,
 starts_at timestamptz not null,
 ends_at timestamptz,
 capacity integer check(capacity>0),
 ticket_price numeric(14,2) not null default 0 check(ticket_price>=0),
 active boolean not null default true
);
create table if not exists public.event_bookings (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null references public.events(id),
 customer_id uuid not null references auth.users(id),
 quantity integer not null check(quantity>0),
 total_amount numeric(14,2) not null check(total_amount>=0),
 status text not null default 'RESERVED' check(status in('RESERVED','PAID','CHECKED_IN','USED','CANCELLED','REFUNDED')),
 qr_token_hash text,
 created_at timestamptz not null default now()
);
create table if not exists public.professional_profiles (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null unique references public.service_providers(id) on delete cascade,
 profession text not null,
 experience_years integer check(experience_years>=0),
 service_area text,
 bio text,
 hourly_rate numeric(14,2) check(hourly_rate>=0),
 active boolean not null default true
);
create table if not exists public.training_courses (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid references public.service_providers(id),
 title text not null,
 description text,
 price numeric(14,2) not null default 0 check(price>=0),
 active boolean not null default true
);
create table if not exists public.training_enrollments (
 id uuid primary key default gen_random_uuid(),
 course_id uuid not null references public.training_courses(id),
 customer_id uuid not null references auth.users(id),
 status text not null default 'ENROLLED' check(status in('ENROLLED','PAID','COMPLETED','CANCELLED')),
 created_at timestamptz not null default now()
);
create table if not exists public.jobs (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid references public.service_providers(id),
 title text not null,
 description text,
 location text,
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.job_applications (
 id uuid primary key default gen_random_uuid(),
 job_id uuid not null references public.jobs(id) on delete cascade,
 applicant_id uuid not null references auth.users(id),
 status text not null default 'SUBMITTED' check(status in('SUBMITTED','REVIEWING','ACCEPTED','REJECTED','WITHDRAWN')),
 created_at timestamptz not null default now(),
 unique(job_id,applicant_id)
);
alter table public.real_estate_listings enable row level security;
alter table public.events enable row level security;
alter table public.event_bookings enable row level security;
alter table public.professional_profiles enable row level security;
alter table public.training_courses enable row level security;
alter table public.training_enrollments enable row level security;
alter table public.jobs enable row level security;
alter table public.job_applications enable row level security;
create policy real_estate_public on public.real_estate_listings for select to anon,authenticated using(active=true and verification_status='VERIFIED');
create policy events_public on public.events for select to anon,authenticated using(active=true);
create policy event_bookings_own on public.event_bookings for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy professional_public on public.professional_profiles for select to anon,authenticated using(active=true);
create policy training_public on public.training_courses for select to anon,authenticated using(active=true);
create policy training_enrollments_own on public.training_enrollments for all to authenticated using(customer_id=(select auth.uid())) with check(customer_id=(select auth.uid()));
create policy jobs_public on public.jobs for select to anon,authenticated using(active=true);
create policy job_applications_own on public.job_applications for all to authenticated using(applicant_id=(select auth.uid())) with check(applicant_id=(select auth.uid()));
