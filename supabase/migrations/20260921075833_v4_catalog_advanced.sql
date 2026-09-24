
create table if not exists public.product_attributes (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 attribute_name text not null,
 attribute_value text not null,
 sort_order integer not null default 0
);
create table if not exists public.product_videos (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 storage_path text not null,
 thumbnail_path text,
 duration_seconds integer,
 sort_order integer not null default 0,
 active boolean not null default true
);
create table if not exists public.product_tags (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 tag text not null,
 unique(product_id,tag)
);
create table if not exists public.shop_followers (
 shop_id uuid not null references public.shops(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(shop_id,user_id)
);
create table if not exists public.product_favorites (
 product_id uuid not null references public.products(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(product_id,user_id)
);
create table if not exists public.recent_views (
 user_id uuid not null references auth.users(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete cascade,
 viewed_at timestamptz not null default now(),
 primary key(user_id,product_id)
);
create table if not exists public.search_history (
 id bigint generated always as identity primary key,
 user_id uuid not null references auth.users(id) on delete cascade,
 query text not null,
 searched_at timestamptz not null default now()
);
create table if not exists public.product_recommendations (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users(id),
 product_id uuid not null references public.products(id) on delete cascade,
 score numeric(10,6),
 reason text,
 generated_at timestamptz not null default now()
);
create index if not exists idx_product_attributes_product on public.product_attributes(product_id);
create index if not exists idx_product_tags_tag on public.product_tags(tag);
create index if not exists idx_search_history_user on public.search_history(user_id,searched_at desc);
create index if not exists idx_recommendations_user on public.product_recommendations(user_id,score desc);

alter table public.product_attributes enable row level security;
alter table public.product_videos enable row level security;
alter table public.product_tags enable row level security;
alter table public.shop_followers enable row level security;
alter table public.product_favorites enable row level security;
alter table public.recent_views enable row level security;
alter table public.search_history enable row level security;
alter table public.product_recommendations enable row level security;

create policy product_attributes_public on public.product_attributes for select to anon,authenticated using(product_id in(select id from public.products where status='ACTIVE' and (not is_expirable or expiry_date is null or expiry_date > current_date)));
create policy product_videos_public on public.product_videos for select to anon,authenticated using(active=true and product_id in(select id from public.products where status='ACTIVE'));
create policy product_tags_public on public.product_tags for select to anon,authenticated using(product_id in(select id from public.products where status='ACTIVE'));
create policy shop_followers_own on public.shop_followers for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy product_favorites_own on public.product_favorites for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy recent_views_own on public.recent_views for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy search_history_own on public.search_history for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy recommendations_own_read on public.product_recommendations for select to authenticated using(user_id=auth.uid());
