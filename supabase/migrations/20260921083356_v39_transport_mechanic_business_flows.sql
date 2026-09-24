
create or replace function public.create_transport_booking(
 p_trip_id uuid,p_quantity integer,p_passengers jsonb default '[]'::jsonb
) returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_trip public.transport_trips%rowtype; v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_quantity is null or p_quantity<1 then raise exception 'invalid_quantity'; end if;
 select * into v_trip from public.transport_trips where id=p_trip_id and status='SCHEDULED' for update;
 if not found then raise exception 'trip_unavailable'; end if;
 insert into public.transport_bookings(trip_id,customer_id,quantity,total_amount,status)
 values(p_trip_id,v_user,p_quantity,v_trip.price*p_quantity,'RESERVED') returning id into v_id;
 return v_id;
end $$;
revoke execute on function public.create_transport_booking(uuid,integer,jsonb) from public,anon,authenticated;
grant execute on function public.create_transport_booking(uuid,integer,jsonb) to authenticated;

create or replace function public.accept_mechanic_quote(p_quote_id uuid)
returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); vq public.mechanic_quotes%rowtype; vi uuid;
begin
 select q.* into vq from public.mechanic_quotes q
 join public.mechanic_requests r on r.id=q.request_id
 where q.id=p_quote_id and r.customer_id=v_user for update;
 if not found then raise exception 'quote_not_found'; end if;
 if vq.status<>'PENDING' or (vq.expires_at is not null and vq.expires_at<=now()) then raise exception 'quote_unavailable'; end if;
 update public.mechanic_quotes set status='ACCEPTED' where id=p_quote_id;
 insert into public.mechanic_interventions(request_id,mechanic_id,quote_id,status,final_amount)
 values(vq.request_id,vq.mechanic_id,vq.id,'ACCEPTED',vq.amount) returning id into vi;
 update public.mechanic_requests set status='ASSIGNED' where id=vq.request_id and status in ('OPEN','QUOTED');
 return vi;
end $$;
revoke execute on function public.accept_mechanic_quote(uuid) from public,anon,authenticated;
grant execute on function public.accept_mechanic_quote(uuid) to authenticated;
