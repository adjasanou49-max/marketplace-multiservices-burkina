
create or replace function public.mark_notification_read(p_notification_id uuid)
returns boolean language plpgsql security invoker
set search_path=pg_catalog,public
as $$
begin
 update public.notifications set read_at=coalesce(read_at,now())
 where id=p_notification_id and user_id=(select auth.uid());
 return found;
end $$;

create or replace function public.register_notification_device(p_platform text,push_token text)
returns uuid language plpgsql security invoker
set search_path=pg_catalog,public
as $$
declare v_id uuid;
begin
 if (select auth.uid()) is null then raise exception 'not_authenticated'; end if;
 if nullif(trim(p_platform),'') is null or nullif(trim(p_push_token),'') is null then raise exception 'invalid_device'; end if;
 insert into public.notification_devices(user_id,platform,push_token,active,last_seen_at)
 values((select auth.uid()),lower(trim(p_platform)),trim(p_push_token),true,now())
 on conflict(push_token) do update set user_id=excluded.user_id,platform=excluded.platform,active=true,last_seen_at=now()
 returning id into v_id;
 return v_id;
end $$;

create or replace function public.create_transport_booking(p_trip_id uuid,p_quantity integer,p_passengers jsonb default '[]'::jsonb)
returns uuid language plpgsql security invoker
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_trip public.transport_trips%rowtype; v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_quantity is null or p_quantity<1 then raise exception 'invalid_quantity'; end if;
 select * into v_trip from public.transport_trips where id=p_trip_id and status='SCHEDULED';
 if not found then raise exception 'trip_unavailable'; end if;
 insert into public.transport_bookings(trip_id,customer_id,quantity,total_amount,status)
 values(p_trip_id,v_user,p_quantity,v_trip.price*p_quantity,'RESERVED') returning id into v_id;
 return v_id;
end $$;

revoke execute on function public.accept_mechanic_quote(uuid) from authenticated;
revoke execute on function public.validate_transport_ticket(uuid) from authenticated;
revoke execute on function public.create_transport_booking(uuid,integer,jsonb) from authenticated;
grant execute on function public.create_transport_booking(uuid,integer,jsonb) to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.register_notification_device(text,text) to authenticated;
