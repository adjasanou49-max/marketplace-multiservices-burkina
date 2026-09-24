begin;

do $block$
declare
  r record;
  v_def text;
  v_new text;
begin
  for r in
    select p.oid
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    join pg_language l on l.oid=p.prolang
    where n.nspname='public'
      and l.lanname='plpgsql'
      and p.prosecdef
      and has_function_privilege('authenticated',p.oid,'EXECUTE')
      and p.proname not like 'admin_%'
      and p.proname not like 'st_%'
      and p.proname not in ('is_admin_actor','get_admin_dashboard','get_admin_refunds')
  loop
    v_def := pg_get_functiondef(r.oid);

    if position('private.require_active_account()' in v_def) = 0
       and position('private.is_active_account()' in v_def) = 0 then
      v_new := regexp_replace(
        v_def,
        E'\nbegin\n',
        E'\nbegin\n  perform private.require_active_account();\n',
        1,
        1,
        'i'
      );

      if v_new <> v_def then
        execute v_new;
      end if;
    end if;
  end loop;
end;
$block$;

commit;