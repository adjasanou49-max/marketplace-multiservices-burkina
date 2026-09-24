
create table if not exists public.returns (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id),
 order_item_id uuid references public.order_items(id),
 customer_id uuid not null references auth.users(id),
 reason text not null,
 status text not null default 'REQUESTED' check (status in ('REQUESTED','APPROVED','REJECTED','PICKUP','RECEIVED','REFUNDED','CLOSED')),
 resolution text check (resolution in ('REFUND','REPLACEMENT','CREDIT')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.return_events (
 id uuid primary key default gen_random_uuid(),
 return_id uuid not null references public.returns(id) on delete cascade,
 actor_id uuid references auth.users(id),
 event_type text not null,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.disputes (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id),
 opened_by uuid not null references auth.users(id),
 against_user_id uuid references auth.users(id),
 reason text not null,
 status text not null default 'OPEN' check (status in ('OPEN','UNDER_REVIEW','RESOLVED','REJECTED','CLOSED')),
 resolution text,
 created_at timestamptz not null default now(),
 resolved_at timestamptz
);
create table if not exists public.dispute_messages (
 id uuid primary key default gen_random_uuid(),
 dispute_id uuid not null references public.disputes(id) on delete cascade,
 sender_id uuid not null references auth.users(id),
 body text,
 attachment_path text,
 created_at timestamptz not null default now(),
 check(body is not null or attachment_path is not null)
);
create table if not exists public.dispute_evidence (
 id uuid primary key default gen_random_uuid(),
 dispute_id uuid not null references public.disputes(id) on delete cascade,
 submitted_by uuid not null references auth.users(id),
 storage_path text not null,
 evidence_type text not null,
 created_at timestamptz not null default now()
);
create table if not exists public.delivery_routes (
 id uuid primary key default gen_random_uuid(),
 courier_id uuid not null references auth.users(id),
 status text not null default 'PLANNED' check(status in ('PLANNED','ACTIVE','COMPLETED','CANCELLED')),
 started_at timestamptz,
 completed_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.delivery_stops (
 id uuid primary key default gen_random_uuid(),
 route_id uuid not null references public.delivery_routes(id) on delete cascade,
 package_id uuid references public.order_packages(id),
 sequence_no integer not null check(sequence_no > 0),
 stop_type text not null check(stop_type in ('PICKUP','DROPOFF')),
 status text not null default 'PENDING' check(status in ('PENDING','ARRIVED','COMPLETED','FAILED')),
 latitude double precision,
 longitude double precision,
 arrived_at timestamptz,
 completed_at timestamptz,
 unique(route_id,sequence_no)
);
create index if not exists idx_returns_customer on public.returns(customer_id,status);
create index if not exists idx_disputes_order on public.disputes(order_id,status);
create index if not exists idx_delivery_routes_courier on public.delivery_routes(courier_id,status);
create index if not exists idx_delivery_stops_route on public.delivery_stops(route_id,sequence_no);

alter table public.returns enable row level security;
alter table public.return_events enable row level security;
alter table public.disputes enable row level security;
alter table public.dispute_messages enable row level security;
alter table public.dispute_evidence enable row level security;
alter table public.delivery_routes enable row level security;
alter table public.delivery_stops enable row level security;

create policy returns_customer_read on public.returns for select to authenticated using(customer_id=auth.uid());
create policy returns_customer_insert on public.returns for insert to authenticated with check(customer_id=auth.uid());
create policy return_events_customer_read on public.return_events for select to authenticated using(return_id in(select id from public.returns where customer_id=auth.uid()));
create policy disputes_participant_read on public.disputes for select to authenticated using(opened_by=auth.uid() or against_user_id=auth.uid());
create policy disputes_participant_insert on public.disputes for insert to authenticated with check(opened_by=auth.uid());
create policy dispute_messages_participant_read on public.dispute_messages for select to authenticated using(dispute_id in(select id from public.disputes where opened_by=auth.uid() or against_user_id=auth.uid()));
create policy dispute_messages_participant_insert on public.dispute_messages for insert to authenticated with check(sender_id=auth.uid() and dispute_id in(select id from public.disputes where opened_by=auth.uid() or against_user_id=auth.uid()));
create policy dispute_evidence_participant on public.dispute_evidence for all to authenticated using(submitted_by=auth.uid()) with check(submitted_by=auth.uid());
create policy delivery_routes_courier_read on public.delivery_routes for select to authenticated using(courier_id=auth.uid());
create policy delivery_stops_courier_read on public.delivery_stops for select to authenticated using(route_id in(select id from public.delivery_routes where courier_id=auth.uid()));
