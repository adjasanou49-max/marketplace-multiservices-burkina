alter table public.notifications
  add column if not exists push_processing_at timestamptz;

create index if not exists idx_notifications_push_processing
on public.notifications(push_processing_at)
where push_sent_at is null;

create or replace function public.claim_notification_for_push(p_notification_id uuid)
returns table (
  id uuid,
  user_id uuid,
  type text,
  title text,
  body text,
  data jsonb,
  push_attempts integer
)
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v public.notifications%rowtype;
  v_now timestamptz := now();
begin
  select * into v
  from public.notifications n
  where n.id=p_notification_id
  for update;

  if not found then return; end if;
  if v.push_sent_at is not null then return; end if;
  if v.push_processing_at is not null
     and v.push_processing_at > v_now - interval '5 minutes' then
    return;
  end if;

  update public.notifications
  set push_processing_at=v_now,
      push_error=null
  where id=p_notification_id;

  return query
  select v.id,v.user_id,v.type,v.title,v.body,v.data,v.push_attempts;
end;
$function$;

revoke all on function public.claim_notification_for_push(uuid) from public;
revoke all on function public.claim_notification_for_push(uuid) from anon;
revoke all on function public.claim_notification_for_push(uuid) from authenticated;
grant execute on function public.claim_notification_for_push(uuid) to service_role;

create or replace function private.notify_order_status()
returns trigger
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_type text;
  v_title text;
  v_body text;
begin
  if tg_op='UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;

  v_type := case new.status::text
    when 'PENDING_PAYMENT' then 'order_created'
    when 'PAID' then 'order_paid'
    when 'CONFIRMED' then 'order_confirmed'
    when 'PREPARING' then 'order_preparing'
    when 'READY_FOR_PICKUP' then 'order_ready'
    when 'PARTIALLY_FULFILLED' then 'order_update'
    when 'IN_TRANSIT' then 'order_in_transit'
    when 'DELIVERED' then 'order_delivered'
    when 'CANCELLED' then 'order_cancelled'
    when 'REFUNDED' then 'order_refunded'
    when 'DISPUTED' then 'order_disputed'
    else 'order_update'
  end;

  v_title := case new.status::text
    when 'PENDING_PAYMENT' then 'Commande créée'
    when 'PAID' then 'Paiement confirmé'
    when 'CONFIRMED' then 'Commande confirmée'
    when 'PREPARING' then 'Commande en préparation'
    when 'READY_FOR_PICKUP' then 'Commande prête'
    when 'PARTIALLY_FULFILLED' then 'Commande partiellement traitée'
    when 'IN_TRANSIT' then 'Commande en livraison'
    when 'DELIVERED' then 'Commande livrée'
    when 'CANCELLED' then 'Commande annulée'
    when 'REFUNDED' then 'Commande remboursée'
    when 'DISPUTED' then 'Commande en litige'
    else 'Mise à jour de commande'
  end;

  v_body := 'Commande ' || left(new.id::text,8) || ' : ' || replace(new.status::text,'_',' ');

  insert into public.notifications(user_id,type,title,body,data)
  values(
    new.customer_id,
    v_type,
    v_title,
    v_body,
    jsonb_build_object('order_id',new.id::text,'type',v_type)
  );

  return new;
exception when others then
  return new;
end;
$function$;

drop trigger if exists orders_push_notification on public.orders;
create trigger orders_push_notification
after insert or update of status on public.orders
for each row execute function private.notify_order_status();

create or replace function private.notify_message()
returns trigger
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
begin
  insert into public.notifications(user_id,type,title,body,data)
  select cm.user_id,'new_message','Nouveau message',
         left(coalesce(new.body,'Nouvelle pièce jointe'),160),
         jsonb_build_object(
           'conversation_id',new.conversation_id::text,
           'message_id',new.id::text,
           'type','new_message',
           'route','/messages'
         )
  from public.conversation_members cm
  where cm.conversation_id=new.conversation_id
    and cm.user_id <> new.sender_id;

  return new;
exception when others then
  return new;
end;
$function$;

drop trigger if exists messages_push_notification on public.messages;
create trigger messages_push_notification
after insert on public.messages
for each row execute function private.notify_message();

create or replace function private.notify_service_request()
returns trigger
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
begin
  if tg_op='UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;

  insert into public.notifications(user_id,type,title,body,data)
  values(
    new.customer_id,
    'service_request',
    'Mise à jour de votre service',
    'Votre demande de service est : ' || replace(new.status,'_',' '),
    jsonb_build_object(
      'service_request_id',new.id::text,
      'type','service_request',
      'route','/services'
    )
  );

  return new;
exception when others then
  return new;
end;
$function$;

drop trigger if exists service_requests_push_notification on public.service_requests;
create trigger service_requests_push_notification
after insert or update of status on public.service_requests
for each row execute function private.notify_service_request();

create or replace function private.notify_mechanic_request()
returns trigger
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
begin
  if tg_op='UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;

  insert into public.notifications(user_id,type,title,body,data)
  values(
    new.customer_id,
    'mechanic_request',
    'Mise à jour de votre dépannage',
    'Votre demande mécanique est : ' || replace(coalesce(new.status,'UNKNOWN'),'_',' '),
    jsonb_build_object(
      'mechanic_request_id',new.id::text,
      'type','mechanic_request',
      'route','/mechanics'
    )
  );

  return new;
exception when others then
  return new;
end;
$function$;

drop trigger if exists mechanic_requests_push_notification on public.mechanic_requests;
create trigger mechanic_requests_push_notification
after insert or update of status on public.mechanic_requests
for each row execute function private.notify_mechanic_request();

create or replace function private.notify_package_status()
returns trigger
language plpgsql
security definer
set search_path to pg_catalog, public
as $function$
declare
  v_customer uuid;
begin
  if tg_op='UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;

  select o.customer_id into v_customer
  from public.order_groups og
  join public.orders o on o.id=og.order_id
  where og.id=new.order_group_id;

  if v_customer is null then return new; end if;

  insert into public.notifications(user_id,type,title,body,data)
  values(
    v_customer,
    'delivery_update',
    'Mise à jour de la livraison',
    'Votre colis est : ' || replace(new.status::text,'_',' '),
    jsonb_build_object('package_id',new.id::text,'type','delivery_update')
  );

  return new;
exception when others then
  return new;
end;
$function$;

drop trigger if exists order_packages_push_notification on public.order_packages;
create trigger order_packages_push_notification
after insert or update of status on public.order_packages
for each row execute function private.notify_package_status();
