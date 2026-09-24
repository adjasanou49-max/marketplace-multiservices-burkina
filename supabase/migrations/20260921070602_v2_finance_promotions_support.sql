
create table if not exists public.commissions (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid not null references public.sellers(id),
 order_group_id uuid references public.order_groups(id),
 rate numeric(7,4) not null check (rate >= 0 and rate <= 100),
 base_amount numeric(14,2) not null check (base_amount >= 0),
 commission_amount numeric(14,2) not null check (commission_amount >= 0),
 currency text not null default 'XOF',
 status text not null default 'PENDING' check (status in ('PENDING','CALCULATED','SETTLED','REVERSED')),
 created_at timestamptz not null default now()
);
create table if not exists public.seller_payouts (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid not null references public.sellers(id),
 amount numeric(14,2) not null check (amount >= 0),
 currency text not null default 'XOF',
 provider text,
 provider_reference text,
 status text not null default 'PENDING' check (status in ('PENDING','PROCESSING','PAID','FAILED','CANCELLED')),
 requested_at timestamptz not null default now(),
 paid_at timestamptz
);
create table if not exists public.refunds (
 id uuid primary key default gen_random_uuid(),
 payment_id uuid references public.payments(id),
 order_id uuid not null references public.orders(id),
 amount numeric(14,2) not null check (amount > 0),
 currency text not null default 'XOF',
 reason text,
 status text not null default 'REQUESTED' check (status in ('REQUESTED','APPROVED','PROCESSING','COMPLETED','REJECTED')),
 provider_reference text,
 created_at timestamptz not null default now(),
 completed_at timestamptz
);
create table if not exists public.promotions (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid references public.sellers(id),
 shop_id uuid references public.shops(id),
 name text not null,
 promotion_type text not null check (promotion_type in ('PERCENT','FIXED','FLASH','BUNDLE')),
 value numeric(14,2) not null check (value >= 0),
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 check (ends_at > starts_at)
);
create table if not exists public.coupons (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid references public.sellers(id),
 code citext not null unique,
 discount_type text not null check (discount_type in ('PERCENT','FIXED')),
 discount_value numeric(14,2) not null check (discount_value > 0),
 min_order_amount numeric(14,2) not null default 0,
 max_uses integer,
 used_count integer not null default 0,
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 active boolean not null default true,
 check (ends_at > starts_at),
 check (max_uses is null or max_uses > 0)
);
create table if not exists public.coupon_usage (
 id uuid primary key default gen_random_uuid(),
 coupon_id uuid not null references public.coupons(id),
 user_id uuid not null references auth.users(id),
 order_id uuid not null references public.orders(id),
 used_at timestamptz not null default now(),
 unique(coupon_id, order_id)
);
create table if not exists public.group_buys (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id),
 seller_id uuid not null references public.sellers(id),
 title text not null,
 target_quantity integer not null check (target_quantity > 1),
 current_quantity integer not null default 0 check (current_quantity >= 0),
 group_price numeric(14,2) not null check (group_price >= 0),
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 status text not null default 'OPEN' check (status in ('DRAFT','OPEN','SUCCESS','FAILED','CANCELLED')),
 check (ends_at > starts_at),
 check (current_quantity <= target_quantity)
);
create table if not exists public.group_buy_members (
 id uuid primary key default gen_random_uuid(),
 group_buy_id uuid not null references public.group_buys(id),
 user_id uuid not null references auth.users(id),
 quantity integer not null check (quantity > 0),
 joined_at timestamptz not null default now(),
 unique(group_buy_id,user_id)
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id),
 type text not null,
 title text not null,
 body text,
 data jsonb not null default '{}'::jsonb,
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.support_tickets (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references auth.users(id),
 subject text not null,
 category text not null,
 priority text not null default 'NORMAL' check (priority in ('LOW','NORMAL','HIGH','URGENT')),
 status text not null default 'OPEN' check (status in ('OPEN','IN_PROGRESS','WAITING_USER','RESOLVED','CLOSED')),
 assigned_to uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.support_messages (
 id uuid primary key default gen_random_uuid(),
 ticket_id uuid not null references public.support_tickets(id) on delete cascade,
 sender_id uuid not null references auth.users(id),
 body text,
 attachment_path text,
 created_at timestamptz not null default now(),
 check (body is not null or attachment_path is not null)
);
create index if not exists idx_commissions_seller on public.commissions(seller_id,status);
create index if not exists idx_payouts_seller on public.seller_payouts(seller_id,status);
create index if not exists idx_refunds_order on public.refunds(order_id,status);
create index if not exists idx_promotions_active on public.promotions(active,starts_at,ends_at);
create index if not exists idx_group_buys_product on public.group_buys(product_id,status);
create index if not exists idx_notifications_user on public.notifications(user_id,created_at desc);
create index if not exists idx_support_tickets_requester on public.support_tickets(requester_id,status);
create index if not exists idx_support_messages_ticket on public.support_messages(ticket_id,created_at);

alter table public.commissions enable row level security;
alter table public.seller_payouts enable row level security;
alter table public.refunds enable row level security;
alter table public.promotions enable row level security;
alter table public.coupons enable row level security;
alter table public.coupon_usage enable row level security;
alter table public.group_buys enable row level security;
alter table public.group_buy_members enable row level security;
alter table public.notifications enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;

create policy commissions_seller_read on public.commissions for select to authenticated using (seller_id in (select id from public.sellers where user_id=auth.uid()));
create policy payouts_seller_read on public.seller_payouts for select to authenticated using (seller_id in (select id from public.sellers where user_id=auth.uid()));
create policy refunds_customer_read on public.refunds for select to authenticated using (order_id in (select id from public.orders where customer_id=auth.uid()));
create policy promotions_public_read on public.promotions for select to anon, authenticated using (active=true and now() between starts_at and ends_at);
create policy coupons_public_read on public.coupons for select to anon, authenticated using (active=true and now() between starts_at and ends_at);
create policy group_buys_public_read on public.group_buys for select to anon, authenticated using (status='OPEN' and now() between starts_at and ends_at);
create policy group_buy_members_own on public.group_buy_members for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy notifications_own on public.notifications for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy support_tickets_own on public.support_tickets for select to authenticated using (requester_id=auth.uid() or assigned_to=auth.uid());
create policy support_tickets_create on public.support_tickets for insert to authenticated with check (requester_id=auth.uid());
create policy support_messages_ticket_participant on public.support_messages for select to authenticated using (
 exists(select 1 from public.support_tickets t where t.id=ticket_id and (t.requester_id=auth.uid() or t.assigned_to=auth.uid()))
);
create policy support_messages_sender_insert on public.support_messages for insert to authenticated with check (
 sender_id=auth.uid() and exists(select 1 from public.support_tickets t where t.id=ticket_id and (t.requester_id=auth.uid() or t.assigned_to=auth.uid()))
);
