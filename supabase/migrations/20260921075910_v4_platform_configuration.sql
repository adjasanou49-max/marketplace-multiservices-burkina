
create table if not exists public.platform_settings (
 key text primary key,
 value jsonb not null default '{}'::jsonb,
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now()
);
create table if not exists public.feature_flags (
 key text primary key,
 enabled boolean not null default false,
 config jsonb not null default '{}'::jsonb,
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now()
);
create table if not exists public.service_categories (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 slug text not null unique,
 icon_url text,
 active boolean not null default true,
 sort_order integer not null default 0
);
create table if not exists public.service_category_fields (
 id uuid primary key default gen_random_uuid(),
 service_category_id uuid not null references public.service_categories(id) on delete cascade,
 field_name text not null,
 field_type text not null check(field_type in('TEXT','NUMBER','BOOLEAN','SELECT','MULTISELECT','DATE','LOCATION','IMAGE')),
 required boolean not null default false,
 options jsonb not null default '[]'::jsonb,
 sort_order integer not null default 0
);
alter table public.platform_settings enable row level security;
alter table public.feature_flags enable row level security;
alter table public.service_categories enable row level security;
alter table public.service_category_fields enable row level security;
create policy service_categories_public on public.service_categories for select to anon,authenticated using(active=true);
create policy service_category_fields_public on public.service_category_fields for select to anon,authenticated using(service_category_id in(select id from public.service_categories where active=true));
