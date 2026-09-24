
drop policy if exists marketplace_modules_admin_read on public.marketplace_modules;
create policy marketplace_modules_admin_read
on public.marketplace_modules
for select
to authenticated
using ((select private.is_admin()));

do $patch$
declare
  def text;
begin
  select pg_get_functiondef(p.oid)
    into def
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname='public'
    and p.proname='create_mechanic_request'
    and pg_get_function_identity_arguments(p.oid)
      = 'p_vehicle_type text, p_problem_type text, p_description text, p_latitude double precision, p_longitude double precision';

  if def is null then
    raise exception 'create_mechanic_request definition not found';
  end if;

  def := replace(
    def,
    '  if (p_latitude is not null and (p_latitude < -90 or p_latitude > 90))
     or (p_longitude is not null and (p_longitude < -180 or p_longitude > 180)) then
    raise exception ''invalid_coordinates'';
  end if;',
    '  if p_latitude is null or p_longitude is null then
    raise exception ''coordinates_required'';
  end if;

  if (p_latitude < -90 or p_latitude > 90)
     or (p_longitude < -180 or p_longitude > 180) then
    raise exception ''invalid_coordinates'';
  end if;'
  );

  execute def;

  select pg_get_functiondef(p.oid)
    into def
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname='public'
    and p.proname='accept_mechanic_quote'
    and pg_get_function_identity_arguments(p.oid) = 'p_quote_id uuid';

  if def is null then
    raise exception 'accept_mechanic_quote definition not found';
  end if;

  def := replace(
    def,
    'status in (''REQUESTED'',''QUOTED'')',
    'status in (''OPEN'',''REQUESTED'',''QUOTED'')'
  );

  execute def;
end
$patch$;
