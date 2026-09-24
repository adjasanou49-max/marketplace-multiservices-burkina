
drop policy if exists freight_requests_own on public.freight_requests;
create policy freight_requests_sender_read
on public.freight_requests for select to authenticated
using ((select auth.uid()) = customer_id);

drop policy if exists parcels_sender_own on public.parcels;
create policy parcels_sender_read
on public.parcels for select to authenticated
using ((select auth.uid()) = sender_id);

create or replace function public.create_freight_request(
  p_pickup jsonb,
  p_delivery jsonb,
  p_weight_kg numeric default null,
  p_volume_m3 numeric default null,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if jsonb_typeof(p_pickup) <> 'object'
     or jsonb_typeof(p_delivery) <> 'object' then
    raise exception 'INVALID_LOCATION';
  end if;
  if p_weight_kg is not null and (p_weight_kg < 0 or p_weight_kg > 100000) then
    raise exception 'INVALID_WEIGHT';
  end if;
  if p_volume_m3 is not null and (p_volume_m3 < 0 or p_volume_m3 > 10000) then
    raise exception 'INVALID_VOLUME';
  end if;

  insert into public.freight_requests(
    customer_id,pickup,delivery,weight_kg,volume_m3,description,status
  )
  values(
    v_user,p_pickup,p_delivery,p_weight_kg,p_volume_m3,
    nullif(trim(p_description),''),'OPEN'
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.create_parcel_request(
  p_recipient_name text,
  p_recipient_phone text,
  p_pickup_address jsonb,
  p_delivery_address jsonb,
  p_weight_kg numeric default null
)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
  v_tracking text;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if nullif(trim(p_recipient_name),'') is null then
    raise exception 'RECIPIENT_NAME_REQUIRED';
  end if;
  if jsonb_typeof(p_pickup_address) <> 'object'
     or jsonb_typeof(p_delivery_address) <> 'object' then
    raise exception 'INVALID_ADDRESS';
  end if;
  if p_weight_kg is not null and (p_weight_kg < 0 or p_weight_kg > 100000) then
    raise exception 'INVALID_WEIGHT';
  end if;

  loop
    v_tracking := 'PKG-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,12));
    exit when not exists(
      select 1 from public.parcels where tracking_code = v_tracking
    );
  end loop;

  insert into public.parcels(
    sender_id,recipient_name,recipient_phone,pickup_address,
    delivery_address,weight_kg,status,tracking_code
  )
  values(
    v_user,trim(p_recipient_name),nullif(trim(p_recipient_phone),''),
    p_pickup_address,p_delivery_address,p_weight_kg,'CREATED',v_tracking
  )
  returning id into v_id;

  insert into public.parcel_events(
    parcel_id,actor_id,status,metadata
  )
  values(
    v_id,v_user,'CREATED',
    jsonb_build_object('source','customer_app')
  );

  return v_id;
end;
$$;

revoke all on function public.create_freight_request(jsonb,jsonb,numeric,numeric,text) from public,anon;
revoke all on function public.create_parcel_request(text,text,jsonb,jsonb,numeric) from public,anon;
grant execute on function public.create_freight_request(jsonb,jsonb,numeric,numeric,text) to authenticated;
grant execute on function public.create_parcel_request(text,text,jsonb,jsonb,numeric) to authenticated;
