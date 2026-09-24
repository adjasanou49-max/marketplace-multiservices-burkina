
do $patch$
declare
  def text;
begin
  select pg_get_functiondef(p.oid)
    into def
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'checkout_cart'
    and pg_get_function_identity_arguments(p.oid)
      = 'p_cart_id uuid, p_delivery_address jsonb, p_delivery_fee numeric, p_coupon_code text, p_idempotency_key text';

  if def is null then
    raise exception 'checkout_cart definition not found';
  end if;

  def := replace(
    def,
    '  v_delivery_address jsonb;',
    '  v_delivery_address jsonb;
  v_delivery_fee_server numeric := 0;'
  );

  def := replace(
    def,
    '  v_total := v_subtotal + p_delivery_fee - v_discount;',
    '  select (public.calculate_delivery_fee(
    p_cart_id,
    jsonb_build_object(
      ''latitude'', v_delivery_address ->> ''latitude'',
      ''longitude'', v_delivery_address ->> ''longitude''
    )
  ) ->> ''customer_fee'')::numeric
    into v_delivery_fee_server;

  v_total := v_subtotal + v_delivery_fee_server - v_discount;'
  );

  def := replace(
    def,
    '    p_delivery_fee,
    v_discount,',
    '    v_delivery_fee_server,
    v_discount,'
  );

  execute def;

  select pg_get_functiondef(p.oid)
    into def
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'checkout_active_cart'
    and pg_get_function_identity_arguments(p.oid)
      = 'p_cart_id uuid, p_delivery_fee numeric, p_delivery_address jsonb';

  if def is null then
    raise exception 'checkout_active_cart definition not found';
  end if;

  def := replace(
    def,
    '  v_seen_shop uuid := null;',
    '  v_seen_shop uuid := null;
  v_delivery_fee_server numeric := 0;'
  );

  def := replace(
    def,
    '  if not exists (select 1 from public.cart_items where cart_id=p_cart_id) then raise exception ''cart_empty''; end if;',
    '  if not exists (select 1 from public.cart_items where cart_id=p_cart_id) then raise exception ''cart_empty''; end if;

  select (public.calculate_delivery_fee(
    p_cart_id,
    coalesce(p_delivery_address, ''{}''::jsonb)
  ) ->> ''customer_fee'')::numeric
    into v_delivery_fee_server;'
  );

  def := replace(
    def,
    '  values(v_user,''PENDING_PAYMENT'',0,p_delivery_fee,0,p_delivery_fee,''XOF'',p_delivery_address)',
    '  values(v_user,''PENDING_PAYMENT'',0,v_delivery_fee_server,0,v_delivery_fee_server,''XOF'',p_delivery_address)'
  );

  def := replace(
    def,
    '  set subtotal=v_subtotal,total=v_subtotal+p_delivery_fee,status=''PENDING_PAYMENT'',updated_at=now()',
    '  set subtotal=v_subtotal,total=v_subtotal+v_delivery_fee_server,status=''PENDING_PAYMENT'',updated_at=now()'
  );

  execute def;
end
$patch$;
