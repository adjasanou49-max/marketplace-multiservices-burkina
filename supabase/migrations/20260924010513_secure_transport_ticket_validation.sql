create or replace function public.validate_transport_ticket(
  p_ticket_id uuid
)
returns boolean
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_user uuid := auth.uid();
  v_booking uuid;
  v_trip uuid;
  v_company uuid;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode='42501';
  end if;

  select t.booking_id
    into v_booking
  from public.transport_tickets t
  where t.id = p_ticket_id
  for update;

  if v_booking is null then
    raise exception 'ticket_not_found';
  end if;

  select tb.trip_id
    into v_trip
  from public.transport_bookings tb
  where tb.id = v_booking
    and tb.status in ('PAID','ISSUED');

  if v_trip is null then
    raise exception 'ticket_not_payable';
  end if;

  select tr.company_id
    into v_company
  from public.transport_trips tt
  join public.transport_routes tr on tr.id = tt.route_id
  where tt.id = v_trip;

  if v_company is null then
    raise exception 'trip_company_not_found';
  end if;

  if not (
    public.is_admin()
    or exists (
      select 1
      from public.transport_companies tc
      where tc.id = v_company
        and tc.owner_user_id = v_user
        and tc.active = true
    )
    or exists (
      select 1
      from public.transport_drivers td
      where td.company_id = v_company
        and td.user_id = v_user
        and td.active = true
    )
  ) then
    raise exception 'ticket_validation_not_authorized' using errcode='42501';
  end if;

  if exists (
    select 1
    from public.transport_checkins
    where ticket_id = p_ticket_id
  ) then
    return false;
  end if;

  insert into public.transport_checkins(
    ticket_id,
    checked_by,
    method
  )
  values(
    p_ticket_id,
    v_user,
    'QR'
  );

  update public.transport_tickets
  set status = 'CHECKED_IN'
  where id = p_ticket_id;

  insert into public.transport_boarding_events(
    ticket_id,
    actor_id,
    event_type
  )
  values(
    p_ticket_id,
    v_user,
    'CHECKED_IN'
  );

  return true;
end;
$function$;
