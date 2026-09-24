
create table if not exists public.legal_documents (
 id uuid primary key default gen_random_uuid(),
 document_type text not null check(document_type in('CGU','CGV','PRIVACY','RETURNS','DELIVERY','SELLER_TERMS','COURIER_TERMS','PROHIBITED_PRODUCTS')),
 version text not null,
 title text not null,
 content text not null,
 published_at timestamptz,
 active boolean not null default false,
 unique(document_type,version)
);
create table if not exists public.user_consents (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 legal_document_id uuid not null references public.legal_documents(id),
 consented_at timestamptz not null default now(),
 ip_hash text,
 unique(user_id,legal_document_id)
);
create table if not exists public.seller_documents (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid not null references public.sellers(id) on delete cascade,
 document_type text not null,
 storage_path text not null,
 verification_status text not null default 'PENDING' check(verification_status in('PENDING','VERIFIED','REJECTED')),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.incidents (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid references auth.users(id),
 order_id uuid references public.orders(id),
 delivery_assignment_id uuid references public.delivery_assignments(id),
 category text not null,
 description text not null,
 severity text not null default 'MEDIUM' check(severity in('LOW','MEDIUM','HIGH','CRITICAL')),
 status text not null default 'OPEN' check(status in('OPEN','INVESTIGATING','RESOLVED','CLOSED')),
 created_at timestamptz not null default now()
);
alter table public.legal_documents enable row level security;
alter table public.user_consents enable row level security;
alter table public.seller_documents enable row level security;
alter table public.incidents enable row level security;
create policy legal_documents_public on public.legal_documents for select to anon,authenticated using(active=true);
create policy user_consents_own on public.user_consents for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy seller_documents_own on public.seller_documents for all to authenticated using(seller_id in(select id from public.sellers where user_id=(select auth.uid()))) with check(seller_id in(select id from public.sellers where user_id=(select auth.uid())));
create policy incidents_reporter_read on public.incidents for select to authenticated using(reporter_id=(select auth.uid()));
create policy incidents_reporter_insert on public.incidents for insert to authenticated with check(reporter_id=(select auth.uid()));
create index if not exists idx_user_consents_user on public.user_consents(user_id);
create index if not exists idx_seller_documents_seller_status on public.seller_documents(seller_id,verification_status);
create index if not exists idx_incidents_status on public.incidents(status,severity);
