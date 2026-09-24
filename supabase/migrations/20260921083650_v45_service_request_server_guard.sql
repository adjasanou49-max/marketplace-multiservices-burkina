
create or replace function public.create_service_request(
 p_service_id uuid,p_scheduled_at timestamptz default null,
 p_latitude double precision default null,p_longitude double precision default null,
 p_description text default null
) returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_service public.services%rowtype; v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_latitude is not null and (p_latitude<-90 or p_latitude>90) then raise exception 'invalid_latitude'; end if;
 if p_longitude is not null and (p_longitude<-180 or p_longitude>180) then raise exception 'invalid_longitude'; end if;
 select * into v_service from public.services where id=p_service_id and active=true for share;
 if not found then raise exception 'service_unavailable'; end if;
 if not exists(select 1 from public.service_providers sp where sp.id=v_service.provider_id and sp.active=true and sp.verification_status='VERIFIED') then
   raise exception 'provider_unavailable';
 end if;
 if p_scheduled_at is not null and exists(
   select 1 from public.provider_time_off pto where pto.provider_id=v_service.provider_id and p_scheduled_at between pto.starts_at and pto.ends_at
 ) then raise exception 'provider_unavailable_at_time'; end if;
 insert into public.service_requests(service_id,customer_id,status,scheduled_at,latitude,longitude,description)
 values(p_service_id,v_user,'REQUESTED',p_scheduled_at,p_latitude,p_longitude,p_description)
 returning id into v_id;
 return v_id;
end $$;
revoke execute on function public.create_service_request(uuid,timestamptz,double precision,double precision,text) from public,anon,authenticated;
grant execute on function public.create_service_request(uuid,timestamptz,double precision,double precision,text) to service_role;
