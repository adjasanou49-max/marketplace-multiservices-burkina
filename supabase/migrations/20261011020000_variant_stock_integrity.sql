-- Variant-level stock integrity. Variant products must reserve, consume, and release
-- stock against the selected SKU, never against the parent product inventory.
BEGIN;

CREATE TABLE IF NOT EXISTS public.variant_inventory (
  variant_id uuid PRIMARY KEY REFERENCES public.product_variants(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity integer NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0 AND reserved_quantity <= quantity),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.variant_inventory_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  variant_id uuid NOT NULL REFERENCES public.product_variants(id) ON DELETE RESTRICT,
  quantity_delta integer NOT NULL CHECK (quantity_delta <> 0),
  reason text NOT NULL CHECK (length(trim(reason)) BETWEEN 1 AND 100),
  actor_id uuid,
  reference_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_variant_inventory_movements_variant_created
  ON public.variant_inventory_movements (variant_id, created_at DESC);

ALTER TABLE public.variant_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.variant_inventory_movements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS variant_inventory_seller_read ON public.variant_inventory;
CREATE POLICY variant_inventory_seller_read
  ON public.variant_inventory
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.product_variants pv
      JOIN public.products p ON p.id = pv.product_id
      JOIN public.shops sh ON sh.id = p.shop_id
      JOIN public.sellers s ON s.id = sh.seller_id
      WHERE pv.id = variant_id AND s.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS variant_inventory_movements_seller_read ON public.variant_inventory_movements;
CREATE POLICY variant_inventory_movements_seller_read
  ON public.variant_inventory_movements
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.product_variants pv
      JOIN public.products p ON p.id = pv.product_id
      JOIN public.shops sh ON sh.id = p.shop_id
      JOIN public.sellers s ON s.id = sh.seller_id
      WHERE pv.id = variant_inventory_movements.variant_id
        AND s.user_id = (SELECT auth.uid())
    )
  );

CREATE OR REPLACE FUNCTION public.reserve_variant_inventory(p_variant_id uuid, p_quantity integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE v_rows integer;
BEGIN
  IF p_variant_id IS NULL OR p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'variant_and_positive_quantity_required';
  END IF;
  UPDATE public.variant_inventory
     SET reserved_quantity = reserved_quantity + p_quantity,
         updated_at = now()
   WHERE variant_id = p_variant_id
     AND quantity - reserved_quantity >= p_quantity;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows = 1;
END
$function$;

CREATE OR REPLACE FUNCTION public.consume_reserved_variant_inventory(p_variant_id uuid, p_quantity integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE v_rows integer;
BEGIN
  IF p_variant_id IS NULL OR p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'variant_and_positive_quantity_required';
  END IF;
  UPDATE public.variant_inventory
     SET quantity = quantity - p_quantity,
         reserved_quantity = reserved_quantity - p_quantity,
         updated_at = now()
   WHERE variant_id = p_variant_id
     AND reserved_quantity >= p_quantity
     AND quantity >= p_quantity;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows = 1;
END
$function$;

CREATE OR REPLACE FUNCTION public.release_variant_inventory(p_variant_id uuid, p_quantity integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE v_rows integer;
BEGIN
  IF p_variant_id IS NULL OR p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'variant_and_positive_quantity_required';
  END IF;
  UPDATE public.variant_inventory
     SET reserved_quantity = reserved_quantity - p_quantity,
         updated_at = now()
   WHERE variant_id = p_variant_id
     AND reserved_quantity >= p_quantity;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows = 1;
END
$function$;

CREATE OR REPLACE FUNCTION public.set_seller_variant_stock(p_variant_id uuid, p_quantity integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_product_id uuid;
  v_old_quantity integer;
  v_reserved integer;
  v_delta integer;
BEGIN
  PERFORM private.require_active_account();
  IF v_user IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING errcode='42501'; END IF;
  IF p_variant_id IS NULL OR p_quantity IS NULL OR p_quantity < 0 OR p_quantity > 1000000 THEN
    RAISE EXCEPTION 'stock_invalid' USING errcode='22023';
  END IF;

  SELECT p.id INTO v_product_id
  FROM public.product_variants pv
  JOIN public.products p ON p.id = pv.product_id
  JOIN public.shops sh ON sh.id = p.shop_id
  JOIN public.sellers s ON s.id = sh.seller_id
  WHERE pv.id = p_variant_id AND s.user_id = v_user
  FOR UPDATE OF pv;

  IF v_product_id IS NULL THEN
    RAISE EXCEPTION 'variant_not_owned' USING errcode='42501';
  END IF;

  INSERT INTO public.variant_inventory(variant_id, quantity, reserved_quantity)
  VALUES (p_variant_id, 0, 0)
  ON CONFLICT (variant_id) DO NOTHING;

  SELECT quantity, reserved_quantity
    INTO v_old_quantity, v_reserved
  FROM public.variant_inventory
  WHERE variant_id = p_variant_id
  FOR UPDATE;

  IF p_quantity < v_reserved THEN
    RAISE EXCEPTION 'stock_below_reserved' USING errcode='22023';
  END IF;

  v_delta := p_quantity - v_old_quantity;
  UPDATE public.variant_inventory
     SET quantity = p_quantity, updated_at = now()
   WHERE variant_id = p_variant_id;

  IF v_delta <> 0 THEN
    INSERT INTO public.variant_inventory_movements(
      variant_id, quantity_delta, reason, actor_id
    ) VALUES (
      p_variant_id, v_delta, 'SELLER_STOCK_ADJUSTMENT', v_user
    );
  END IF;
END
$function$;

REVOKE ALL ON FUNCTION public.reserve_variant_inventory(uuid, integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.consume_reserved_variant_inventory(uuid, integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.release_variant_inventory(uuid, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_variant_inventory(uuid, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.consume_reserved_variant_inventory(uuid, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.release_variant_inventory(uuid, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.set_seller_variant_stock(uuid, integer) TO authenticated;

-- Rewrite the existing checkout definitions by changing only the stock reservation
-- statement, preserving all current pricing, coupon, address and idempotency logic.
DO $migration$
DECLARE
  v_def text;
  v_new text;
  v_old text;
BEGIN
  SELECT pg_get_functiondef('public.checkout_cart(uuid,jsonb,numeric,text,text)'::regprocedure) INTO v_def;
  v_old := $old$    select public.reserve_inventory(
      v_item.product_id,
      v_item.quantity
    ) into v_reserved;

    if not v_reserved then
      raise exception 'insufficient_inventory';
    end if;$old$;
  v_new := $new$    if v_item.variant_id is null then
      v_reserved := public.reserve_inventory(v_item.product_id, v_item.quantity);
    else
      v_reserved := public.reserve_variant_inventory(v_item.variant_id, v_item.quantity);
    end if;

    if not v_reserved then
      raise exception 'insufficient_inventory';
    end if;$new$;
  IF position(v_old IN v_def) = 0 THEN RAISE EXCEPTION 'checkout_cart_stock_block_not_found'; END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  SELECT pg_get_functiondef('public.checkout_active_cart(uuid,numeric,jsonb)'::regprocedure) INTO v_def;
  v_old := $old$    if not public.reserve_inventory(v_item.product_id,v_item.quantity) then raise exception 'insufficient_inventory'; end if;$old$;
  v_new := $new$    if v_item.variant_id is null then
      if not public.reserve_inventory(v_item.product_id, v_item.quantity) then raise exception 'insufficient_inventory'; end if;
    else
      if not public.reserve_variant_inventory(v_item.variant_id, v_item.quantity) then raise exception 'insufficient_inventory'; end if;
    end if;$new$;
  IF position(v_old IN v_def) = 0 THEN RAISE EXCEPTION 'checkout_active_cart_stock_block_not_found'; END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  SELECT pg_get_functiondef('public.cancel_unpaid_order(uuid)'::regprocedure) INTO v_def;
  v_old := $old$  for v_item in
    select oi.product_id, sum(oi.quantity)::integer as qty
    from public.order_items oi
    join public.order_groups og on og.id=oi.order_group_id
    where og.order_id=p_order_id
    group by oi.product_id
  loop
    perform public.release_inventory(v_item.product_id,v_item.qty);
  end loop;$old$;
  v_new := $new$  for v_item in
    select oi.product_id, oi.variant_id, sum(oi.quantity)::integer as qty
    from public.order_items oi
    join public.order_groups og on og.id=oi.order_group_id
    where og.order_id=p_order_id
    group by oi.product_id, oi.variant_id
  loop
    if v_item.variant_id is null then
      perform public.release_inventory(v_item.product_id,v_item.qty);
    else
      perform public.release_variant_inventory(v_item.variant_id,v_item.qty);
    end if;
  end loop;$new$;
  IF position(v_old IN v_def) = 0 THEN RAISE EXCEPTION 'cancel_unpaid_order_stock_block_not_found'; END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  SELECT pg_get_functiondef('public.process_payment_event(uuid,text,payment_status,text,numeric,jsonb)'::regprocedure) INTO v_def;
  v_old := $old$      for v_item in
        select oi.product_id, oi.quantity
        from public.order_items oi
        join public.order_groups og on og.id=oi.order_group_id
        where og.order_id=v_order.id
      loop
        perform public.release_inventory(v_item.product_id,v_item.quantity);
      end loop;$old$;
  v_new := $new$      for v_item in
        select oi.product_id, oi.variant_id, oi.quantity
        from public.order_items oi
        join public.order_groups og on og.id=oi.order_group_id
        where og.order_id=v_order.id
      loop
        if v_item.variant_id is null then
          perform public.release_inventory(v_item.product_id,v_item.quantity);
        else
          perform public.release_variant_inventory(v_item.variant_id,v_item.quantity);
        end if;
      end loop;$new$;
  IF position(v_old IN v_def) = 0 THEN RAISE EXCEPTION 'process_payment_event_release_block_not_found'; END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  SELECT pg_get_functiondef('public.transition_order_status(uuid,order_status,text)'::regprocedure) INTO v_def;
  v_old := $old$    for v_item in
      select oi.product_id, oi.quantity
      from public.order_items oi
      join public.order_groups og on og.id = oi.order_group_id
      where og.order_id = p_order_id
    loop
      perform public.release_inventory(v_item.product_id, v_item.quantity);
    end loop;$old$;
  v_new := $new$    for v_item in
      select oi.product_id, oi.variant_id, oi.quantity
      from public.order_items oi
      join public.order_groups og on og.id = oi.order_group_id
      where og.order_id = p_order_id
    loop
      if v_item.variant_id is null then
        perform public.release_inventory(v_item.product_id, v_item.quantity);
      else
        perform public.release_variant_inventory(v_item.variant_id, v_item.quantity);
      end if;
    end loop;$new$;
  IF position(v_old IN v_def) = 0 THEN RAISE EXCEPTION 'transition_order_status_release_block_not_found'; END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;

  -- Consumption after pickup must use the same stock unit that checkout reserved.
  EXECUTE $fn$
    CREATE OR REPLACE FUNCTION public.consume_order_inventory(p_order_id uuid)
    RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $body$
    DECLARE v_count integer := 0; v_item record; v_ok boolean;
    BEGIN
      IF p_order_id IS NULL THEN RAISE EXCEPTION 'order_required'; END IF;
      FOR v_item IN
        SELECT oi.product_id, oi.variant_id, oi.quantity
        FROM public.order_items oi
        JOIN public.order_groups og ON og.id = oi.order_group_id
        WHERE og.order_id = p_order_id
      LOOP
        IF v_item.variant_id IS NULL THEN
          v_ok := public.consume_reserved_inventory(v_item.product_id, v_item.quantity);
        ELSE
          v_ok := public.consume_reserved_variant_inventory(v_item.variant_id, v_item.quantity);
        END IF;
        IF NOT v_ok THEN RAISE EXCEPTION 'reserved_inventory_insufficient'; END IF;
        v_count := v_count + 1;
      END LOOP;
      RETURN v_count;
    END
    $body$;
  $fn$;

  EXECUTE $fn$
    CREATE OR REPLACE FUNCTION public.consume_package_inventory(p_package_id uuid)
    RETURNS integer LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $body$
    DECLARE v_count integer := 0; v_item record; v_ok boolean;
    BEGIN
      IF p_package_id IS NULL THEN RAISE EXCEPTION 'package_required'; END IF;
      INSERT INTO public.package_inventory_consumptions(package_id)
      VALUES (p_package_id)
      ON CONFLICT (package_id) DO NOTHING;
      IF NOT FOUND THEN RETURN 0; END IF;

      FOR v_item IN
        SELECT oi.product_id, oi.variant_id, oi.quantity
        FROM public.order_items oi
        JOIN public.order_groups og ON og.id = oi.order_group_id
        JOIN public.order_packages op ON op.order_group_id = og.id
        WHERE op.id = p_package_id
      LOOP
        IF v_item.variant_id IS NULL THEN
          v_ok := public.consume_reserved_inventory(v_item.product_id, v_item.quantity);
        ELSE
          v_ok := public.consume_reserved_variant_inventory(v_item.variant_id, v_item.quantity);
        END IF;
        IF NOT v_ok THEN RAISE EXCEPTION 'reserved_inventory_insufficient'; END IF;
        v_count := v_count + 1;
      END LOOP;
      RETURN v_count;
    END
    $body$;
  $fn$;

  -- Parent stock is only for products without variants.
  SELECT pg_get_functiondef('public.set_seller_stock(uuid,integer)'::regprocedure) INTO v_def;
  v_old := $old$  if not exists (
    select 1
    from public.products p
    join public.shops sh on sh.id=p.shop_id
    join public.sellers se on se.id=sh.seller_id
    where p.id=p_product_id and se.user_id=v_user
  ) then
    raise exception 'product_not_owned' using errcode='42501';
  end if;$old$;
  v_new := $new$  if not exists (
    select 1
    from public.products p
    join public.shops sh on sh.id=p.shop_id
    join public.sellers se on se.id=sh.seller_id
    where p.id=p_product_id and se.user_id=v_user
  ) then
    raise exception 'product_not_owned' using errcode='42501';
  end if;

  if exists (select 1 from public.product_variants pv where pv.product_id=p_product_id) then
    raise exception 'variant_stock_required' using errcode='22023';
  end if;$new$;
  IF position(v_old IN v_def) = 0 THEN RAISE EXCEPTION 'set_seller_stock_ownership_block_not_found'; END IF;
  v_def := replace(v_def, v_old, v_new);
  EXECUTE v_def;
END
$migration$;

COMMIT;
