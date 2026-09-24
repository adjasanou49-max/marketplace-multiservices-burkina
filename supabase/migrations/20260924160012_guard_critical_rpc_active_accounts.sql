begin;

create or replace function private.require_active_account()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
begin
  if not private.is_active_account() then
    raise exception 'account_not_active' using errcode='42501';
  end if;
end;
$function$;

revoke all on function private.require_active_account() from public, anon, authenticated;

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
      and p.proname in (
        'accept_mechanic_quote',
        'add_to_cart',
        'apply_to_job',
        'checkout_cart',
        'create_accommodation_booking',
        'create_beauty_booking',
        'create_digital_order',
        'create_freight_request',
        'create_home_service_request',
        'create_mechanic_request',
        'create_parcel_request',
        'create_payment_intent',
        'create_review',
        'create_ride_request',
        'create_service_request',
        'create_transport_booking_secure',
        'create_vehicle_rental_booking',
        'enroll_training_course',
        'join_group_buy',
        'prepare_payment_processing',
        'record_courier_location',
        'request_refund',
        'request_seller_payout_secure',
        'reserve_event_ticket',
        'schedule_mechanic_time_off',
        'set_cart_item_quantity',
        'set_mechanic_availability'
      )
  loop
    v_def := pg_get_functiondef(r.oid);
    v_new := regexp_replace(
      v_def,
      '\bbegin\b',
      E'begin\n  perform private.require_active_account();',
      1,
      1,
      'i'
    );

    if v_new <> v_def then
      execute v_new;
    end if;
  end loop;
end;
$block$;

commit;