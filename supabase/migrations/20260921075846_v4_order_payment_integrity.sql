
create table if not exists public.payment_events (
 id uuid primary key default gen_random_uuid(),
 payment_id uuid not null references public.payments(id) on delete cascade,
 event_type text not null,
 provider_reference text,
 payload jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.seller_ledger (
 id bigint generated always as identity primary key,
 seller_id uuid not null references public.sellers(id),
 order_group_id uuid references public.order_groups(id),
 entry_type text not null check(entry_type in('SALE','COMMISSION','REFUND','PAYOUT','ADJUSTMENT')),
 amount numeric(14,2) not null,
 currency text not null default 'XOF',
 reference_id uuid,
 created_at timestamptz not null default now()
);
create table if not exists public.order_events (
 id bigint generated always as identity primary key,
 order_id uuid not null references public.orders(id) on delete cascade,
 actor_id uuid references auth.users(id),
 status public.order_status not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists idx_payment_events_payment on public.payment_events(payment_id,created_at desc);
create index if not exists idx_seller_ledger_seller on public.seller_ledger(seller_id,created_at desc);
create index if not exists idx_order_events_order on public.order_events(order_id,created_at desc);

alter table public.payment_events enable row level security;
alter table public.seller_ledger enable row level security;
alter table public.order_events enable row level security;

create policy payment_events_customer_read on public.payment_events for select to authenticated using(payment_id in(select p.id from public.payments p join public.orders o on o.id=p.order_id where o.customer_id=auth.uid()));
create policy seller_ledger_seller_read on public.seller_ledger for select to authenticated using(seller_id in(select id from public.sellers where user_id=auth.uid()));
create policy order_events_customer_read on public.order_events for select to authenticated using(order_id in(select id from public.orders where customer_id=auth.uid()));
