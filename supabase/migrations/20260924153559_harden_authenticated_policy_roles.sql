begin;

do $block$
declare
  p record;
begin
  for p in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and roles::text = '{public}'
      and (
        coalesce(qual,'') like '%auth.uid()%'
        or coalesce(with_check,'') like '%auth.uid()%'
        or coalesce(qual,'') like '%private.is_admin%'
        or coalesce(with_check,'') like '%private.is_admin%'
      )
  loop
    execute format(
      'alter policy %I on %I.%I to authenticated',
      p.policyname, p.schemaname, p.tablename
    );
  end loop;
end;
$block$;

alter policy audit_logs_no_client_access
  on public.audit_logs to authenticated;

revoke all on all tables in schema public from public, anon, authenticated;
grant all on all tables in schema public to service_role;

do $grant$
declare
  p record;
  r text;
  target_role text;
  grant_priv text;
begin
  for p in
    select schemaname, tablename, roles, cmd
    from pg_policies
    where schemaname = 'public'
  loop
    grant_priv := case p.cmd
      when 'SELECT' then 'SELECT'
      when 'INSERT' then 'INSERT'
      when 'UPDATE' then 'UPDATE'
      when 'DELETE' then 'DELETE'
      when 'ALL' then 'SELECT, INSERT, UPDATE, DELETE'
      else null
    end;

    if grant_priv is null then
      continue;
    end if;

    foreach r in array p.roles
    loop
      target_role := case r
        when 'public' then 'authenticated'
        else r
      end;

      if target_role in ('anon','authenticated') then
        execute format(
          'grant %s on table %I.%I to %I',
          grant_priv, p.schemaname, p.tablename, target_role
        );

        if r = 'public' and target_role = 'authenticated' then
          execute format(
            'grant %s on table %I.%I to anon',
            grant_priv, p.schemaname, p.tablename
          );
        end if;
      end if;
    end loop;
  end loop;
end;
$grant$;

revoke all on table public.spatial_ref_sys from public, anon, authenticated;
revoke all on table public.geography_columns from public, anon, authenticated;
revoke all on table public.geometry_columns from public, anon, authenticated;
grant all on table public.spatial_ref_sys to service_role;
grant all on table public.geography_columns to service_role;
grant all on table public.geometry_columns to service_role;

commit;