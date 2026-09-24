
create table public.fraud_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid references auth.users(id),
 target_user_id uuid references auth.users(id),
 order_id uuid references public.orders(id),
 reason text not null,
 status text not null default 'OPEN' check(status in('OPEN','REVIEWING','CONFIRMED','DISMISSED','CLOSED')),
 created_at timestamptz not null default now()
);
alter table public.fraud_reports enable row level security;
create policy fraud_reports_own_read on public.fraud_reports for select to authenticated using(reporter_id=auth.uid());
create policy fraud_reports_own_insert on public.fraud_reports for insert to authenticated with check(reporter_id=auth.uid());
