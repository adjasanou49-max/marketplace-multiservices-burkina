
create table if not exists public.media_assets (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid references auth.users(id),
 storage_path text not null unique,
 media_type text not null check(media_type in('IMAGE','VIDEO','DOCUMENT','AUDIO')),
 mime_type text,
 size_bytes bigint check(size_bytes>=0),
 width integer,
 height integer,
 duration_seconds integer,
 visibility text not null default 'PRIVATE' check(visibility in('PRIVATE','PUBLIC')),
 created_at timestamptz not null default now()
);
create table if not exists public.notification_devices (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 platform text not null check(platform in('ANDROID','IOS')),
 push_token text not null unique,
 active boolean not null default true,
 last_seen_at timestamptz not null default now()
);
create table if not exists public.notification_preferences (
 user_id uuid primary key references auth.users(id) on delete cascade,
 orders boolean not null default true,
 promotions boolean not null default true,
 messages boolean not null default true,
 delivery boolean not null default true,
 services boolean not null default true,
 updated_at timestamptz not null default now()
);
alter table public.media_assets enable row level security;
alter table public.notification_devices enable row level security;
alter table public.notification_preferences enable row level security;
create policy media_assets_own on public.media_assets for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy notification_devices_own on public.notification_devices for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy notification_preferences_own on public.notification_preferences for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
