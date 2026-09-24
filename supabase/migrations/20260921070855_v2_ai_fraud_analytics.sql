
create table if not exists public.fraud_events (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users(id),
 event_type text not null,
 risk_score numeric(6,3),
 severity text not null default 'LOW' check(severity in('LOW','MEDIUM','HIGH','CRITICAL')),
 entity_type text,
 entity_id uuid,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.security_events (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users(id),
 event_type text not null,
 ip_hash text,
 device_hash text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.ai_tasks (
 id uuid primary key default gen_random_uuid(),
 task_type text not null,
 entity_type text,
 entity_id uuid,
 status text not null default 'QUEUED' check(status in('QUEUED','RUNNING','SUCCEEDED','FAILED','REVIEW')),
 input jsonb not null default '{}'::jsonb,
 output jsonb,
 created_at timestamptz not null default now(),
 completed_at timestamptz
);
create table if not exists public.moderation_cases (
 id uuid primary key default gen_random_uuid(),
 entity_type text not null,
 entity_id uuid not null,
 reason text not null,
 severity text not null default 'MEDIUM' check(severity in('LOW','MEDIUM','HIGH','CRITICAL')),
 status text not null default 'OPEN' check(status in('OPEN','IN_REVIEW','RESOLVED','DISMISSED')),
 assigned_to uuid references auth.users(id),
 created_at timestamptz not null default now(),
 resolved_at timestamptz
);
create table if not exists public.analytics_events (
 id bigint generated always as identity primary key,
 user_id uuid references auth.users(id),
 event_name text not null,
 properties jsonb not null default '{}'::jsonb,
 occurred_at timestamptz not null default now()
);
create index if not exists idx_fraud_user_time on public.fraud_events(user_id,created_at desc);
create index if not exists idx_security_time on public.security_events(created_at desc);
create index if not exists idx_ai_tasks_status on public.ai_tasks(status,created_at);
create index if not exists idx_moderation_status on public.moderation_cases(status,created_at);
create index if not exists idx_analytics_event on public.analytics_events(event_name,occurred_at desc);

alter table public.fraud_events enable row level security;
alter table public.security_events enable row level security;
alter table public.ai_tasks enable row level security;
alter table public.moderation_cases enable row level security;
alter table public.analytics_events enable row level security;

create policy fraud_events_own_read on public.fraud_events for select to authenticated using(user_id=auth.uid());
create policy security_events_own_read on public.security_events for select to authenticated using(user_id=auth.uid());
create policy analytics_events_own_read on public.analytics_events for select to authenticated using(user_id=auth.uid());
create policy analytics_events_own_insert on public.analytics_events for insert to authenticated with check(user_id=auth.uid());
