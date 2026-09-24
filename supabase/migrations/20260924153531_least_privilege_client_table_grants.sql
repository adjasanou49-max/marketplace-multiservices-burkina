begin;

revoke all on all tables in schema public from public, anon, authenticated;
grant all on all tables in schema public to service_role;

do $block$
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
$block$;

revoke all on table public.spatial_ref_sys from public, anon, authenticated;
revoke all on table public.geography_columns from public, anon, authenticated;
revoke all on table public.geometry_columns from public, anon, authenticated;
grant all on table public.spatial_ref_sys to service_role;
grant all on table public.geography_columns to service_role;
grant all on table public.geometry_columns to service_role;

commit;