
create table if not exists public.marketplace_modules (
  key text primary key,
  label text not null,
  route text not null unique,
  icon_name text,
  enabled boolean not null default false,
  sort_order integer not null default 0,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.marketplace_modules enable row level security;

grant select on public.marketplace_modules to anon, authenticated;
grant insert, update, delete on public.marketplace_modules to authenticated;

drop policy if exists marketplace_modules_client_read on public.marketplace_modules;
create policy marketplace_modules_client_read
on public.marketplace_modules
for select
to anon, authenticated
using (enabled = true);

drop policy if exists marketplace_modules_admin_manage on public.marketplace_modules;
create policy marketplace_modules_admin_manage
on public.marketplace_modules
for all
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

insert into public.marketplace_modules (key,label,route,icon_name,enabled,sort_order)
values
  ('marketplace','Marketplace','/','storefront',true,10),
  ('restaurants','Restaurants','/restaurants','restaurant',true,20),
  ('transport','Compagnies de transport','/transport','directions_bus',false,30),
  ('mechanics','Mécaniciens','/mechanics','build',false,40),
  ('expiry','Expiration proche','/expiry','event_busy',false,50),
  ('promotions','Promotions','/promotions','local_offer',true,60),
  ('follows','Suivis','/follows','favorite',true,70),
  ('services','Services','/services','handyman',false,80)
on conflict (key) do update
set label=excluded.label,
    route=excluded.route,
    icon_name=excluded.icon_name,
    sort_order=excluded.sort_order,
    updated_at=now();

create index if not exists idx_marketplace_modules_enabled_sort
on public.marketplace_modules(enabled, sort_order);
