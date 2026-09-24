
create schema if not exists private;

create or replace function private.has_role(p_role public.user_role)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
 select exists(
   select 1 from public.user_roles ur
   where ur.user_id = auth.uid() and ur.role = p_role
 )
$$;

revoke all on function private.has_role(public.user_role) from public, anon, authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
 select exists(
   select 1 from public.admin_users au
   where au.user_id = auth.uid() and au.active = true
 )
$$;

revoke all on function private.is_admin() from public, anon, authenticated;

create index if not exists idx_user_roles_user_role on public.user_roles(user_id,role);
