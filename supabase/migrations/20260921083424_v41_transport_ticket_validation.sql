
create or replace function public.validate_transport_ticket(p_ticket_id uuid)
returns boolean language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_booking uuid;
begin
 select booking_id into v_booking from public.transport_tickets where id=p_ticket_id for update;
 if not found then raise exception 'ticket_not_found'; end if;
 if not exists (
   select 1 from public.transport_bookings tb
   where tb.id=v_booking and tb.status in ('PAID','ISSUED','RESERVED')
 ) then raise exception 'booking_invalid'; end if;
 if exists(select 1 from public.transport_checkins where ticket_id=p_ticket_id) then return false; end if;
 insert into public.transport_checkins(ticket_id,checked_by,method)
 values(p_ticket_id,v_user,'QR');
 update public.transport_tickets set status='CHECKED_IN' where id=p_ticket_id;
 insert into public.transport_boarding_events(ticket_id,actor_id,event_type)
 values(p_ticket_id,v_user,'CHECKED_IN');
 return true;
end $$;
revoke execute on function public.validate_transport_ticket(uuid) from public,anon,authenticated;
grant execute on function public.validate_transport_ticket(uuid) to authenticated;
