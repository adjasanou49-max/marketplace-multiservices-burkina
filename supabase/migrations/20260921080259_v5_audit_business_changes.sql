
create table if not exists public.admin_change_log (
 id bigint generated always as identity primary key,
 actor_id uuid not null references auth.users(id),
 entity_type text not null,
 entity_id uuid,
 action text not null,
 before_data jsonb,
 after_data jsonb,
 created_at timestamptz not null default now()
);
alter table public.admin_change_log enable row level security;
create policy admin_change_log_admin_read on public.admin_change_log
for select to authenticated using((select private.is_admin()));
create policy admin_change_log_admin_insert on public.admin_change_log
for insert to authenticated with check((select private.is_admin()) and actor_id=auth.uid());
create index if not exists idx_admin_change_log_entity on public.admin_change_log(entity_type,entity_id,created_at desc);
create index if not exists idx_admin_change_log_actor on public.admin_change_log(actor_id,created_at desc);
