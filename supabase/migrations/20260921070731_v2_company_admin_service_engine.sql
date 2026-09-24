
create table if not exists public.company (
 id uuid primary key default gen_random_uuid(),
 legal_name text not null unique,
 rccm text,
 ifu text,
 created_at timestamptz not null default now()
);
create table if not exists public.company_members (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.company(id) on delete cascade,
 user_id uuid not null references auth.users(id),
 role_title text not null,
 status text not null default 'ACTIVE' check(status in('ACTIVE','INACTIVE')),
 joined_at timestamptz not null default now(),
 unique(company_id,user_id)
);
create table if not exists public.share_classes (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.company(id) on delete cascade,
 name text not null,
 nominal_value numeric(14,2) not null check(nominal_value>0),
 unique(company_id,name)
);
create table if not exists public.shareholdings (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null references public.company(id) on delete cascade,
 shareholder_id uuid not null references auth.users(id),
 share_class_id uuid not null references public.share_classes(id),
 shares numeric(18,4) not null check(shares>=0),
 paid_amount numeric(14,2) not null default 0 check(paid_amount>=0),
 status text not null default 'ACTIVE' check(status in('ACTIVE','SUSPENDED','TRANSFERRED')),
 unique(company_id,shareholder_id,share_class_id)
);
create table if not exists public.share_payments (
 id uuid primary key default gen_random_uuid(),
 holding_id uuid not null references public.shareholdings(id) on delete cascade,
 amount numeric(14,2) not null check(amount>0),
 payment_reference text,
 status text not null default 'PENDING' check(status in('PENDING','PAID','REJECTED')),
 paid_at timestamptz
);
create table if not exists public.admin_roles (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 description text
);
create table if not exists public.admin_users (
 user_id uuid primary key references auth.users(id),
 admin_role_id uuid not null references public.admin_roles(id),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.account_actions (
 id uuid primary key default gen_random_uuid(),
 target_user_id uuid not null references auth.users(id),
 actor_id uuid not null references auth.users(id),
 action text not null check(action in('SUSPEND','BLOCK','REACTIVATE')),
 reason text,
 created_at timestamptz not null default now()
);
create table if not exists public.service_providers (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null unique references auth.users(id),
 provider_type text not null,
 display_name text not null,
 description text,
 verification_status public.verification_status not null default 'PENDING',
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.services (
 id uuid primary key default gen_random_uuid(),
 provider_id uuid not null references public.service_providers(id) on delete cascade,
 category text not null,
 name text not null,
 description text,
 price numeric(14,2),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.service_requests (
 id uuid primary key default gen_random_uuid(),
 service_id uuid not null references public.services(id),
 customer_id uuid not null references auth.users(id),
 status text not null default 'REQUESTED' check(status in('REQUESTED','QUOTED','ACCEPTED','IN_PROGRESS','COMPLETED','CANCELLED')),
 scheduled_at timestamptz,
 latitude double precision,
 longitude double precision,
 description text,
 created_at timestamptz not null default now()
);
create table if not exists public.service_quotes (
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null references public.service_requests(id) on delete cascade,
 provider_id uuid not null references public.service_providers(id),
 amount numeric(14,2) not null check(amount>=0),
 currency text not null default 'XOF',
 status text not null default 'PROPOSED' check(status in('PROPOSED','ACCEPTED','REJECTED','EXPIRED')),
 created_at timestamptz not null default now()
);
create index if not exists idx_company_members_user on public.company_members(user_id);
create index if not exists idx_shareholdings_company on public.shareholdings(company_id);
create index if not exists idx_service_requests_customer on public.service_requests(customer_id,status);
create index if not exists idx_services_category on public.services(category,active);

alter table public.company enable row level security;
alter table public.company_members enable row level security;
alter table public.share_classes enable row level security;
alter table public.shareholdings enable row level security;
alter table public.share_payments enable row level security;
alter table public.admin_roles enable row level security;
alter table public.admin_users enable row level security;
alter table public.account_actions enable row level security;
alter table public.service_providers enable row level security;
alter table public.services enable row level security;
alter table public.service_requests enable row level security;
alter table public.service_quotes enable row level security;

create policy company_member_read on public.company for select to authenticated using(id in(select company_id from public.company_members where user_id=auth.uid()));
create policy company_members_own_read on public.company_members for select to authenticated using(user_id=auth.uid());
create policy shares_own_read on public.shareholdings for select to authenticated using(shareholder_id=auth.uid());
create policy share_payments_own_read on public.share_payments for select to authenticated using(holding_id in(select id from public.shareholdings where shareholder_id=auth.uid()));
create policy admin_self_read on public.admin_users for select to authenticated using(user_id=auth.uid());
create policy account_actions_target_read on public.account_actions for select to authenticated using(target_user_id=auth.uid());
create policy providers_public_read on public.service_providers for select to anon,authenticated using(active=true and verification_status='VERIFIED');
create policy services_public_read on public.services for select to anon,authenticated using(active=true);
create policy service_requests_customer on public.service_requests for all to authenticated using(customer_id=auth.uid()) with check(customer_id=auth.uid());
create policy service_quotes_customer on public.service_quotes for select to authenticated using(request_id in(select id from public.service_requests where customer_id=auth.uid()));
