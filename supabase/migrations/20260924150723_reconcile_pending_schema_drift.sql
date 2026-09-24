-- Reconcile schema changes that were partially applied directly in production.
-- Only missing end-state pieces are created here; existing push functions/triggers remain intact.

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS push_processing_at timestamptz;

CREATE INDEX IF NOT EXISTS idx_notification_devices_user_active
  ON public.notification_devices(user_id, active);

CREATE INDEX IF NOT EXISTS idx_notifications_push_queue
  ON public.notifications(created_at)
  WHERE push_sent_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_push_processing
  ON public.notifications(push_processing_at)
  WHERE push_sent_at IS NULL;

CREATE OR REPLACE FUNCTION public.enforce_one_active_cart()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO pg_catalog, public
AS $$
DECLARE
  existing_id uuid;
BEGIN
  IF NEW.status <> 'ACTIVE' THEN
    RETURN NEW;
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(NEW.customer_id::text, 0)
  );

  SELECT id
    INTO existing_id
  FROM public.carts
  WHERE customer_id = NEW.customer_id
    AND status = 'ACTIVE'
    AND id <> NEW.id
  ORDER BY created_at DESC NULLS LAST, id DESC
  LIMIT 1;

  IF existing_id IS NOT NULL THEN
    RAISE EXCEPTION 'active cart already exists for customer'
      USING ERRCODE = '23505';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS carts_one_active_per_customer_trigger
ON public.carts;

CREATE TRIGGER carts_one_active_per_customer_trigger
BEFORE INSERT OR UPDATE OF customer_id, status
ON public.carts
FOR EACH ROW
EXECUTE FUNCTION public.enforce_one_active_cart();

ALTER POLICY courier_locations_read
ON public.courier_locations
USING (
  courier_id = (SELECT auth.uid())
  OR (
    id = (
      SELECT cl.id
      FROM public.courier_locations cl
      WHERE cl.courier_id = courier_locations.courier_id
      ORDER BY cl.recorded_at DESC, cl.id DESC
      LIMIT 1
    )
    AND EXISTS (
      SELECT 1
      FROM public.delivery_assignments da
      JOIN public.order_packages op ON op.id = da.package_id
      JOIN public.order_groups og ON og.id = op.order_group_id
      JOIN public.orders o ON o.id = og.order_id
      WHERE da.courier_id = courier_locations.courier_id
        AND o.customer_id = (SELECT auth.uid())
        AND op.delivered_at IS NULL
    )
  )
);

ALTER POLICY products_read
ON public.products
USING (
  public.is_admin_actor()
  OR (
    status = 'ACTIVE'::public.product_status
    AND (
      NOT is_expirable
      OR expiry_date IS NULL
      OR expiry_date >= CURRENT_DATE
    )
    AND EXISTS (
      SELECT 1
      FROM public.shops s
      WHERE s.id = products.shop_id
        AND s.status = 'ACTIVE'::public.shop_status
        AND s.verification_status = 'VERIFIED'::public.verification_status
    )
  )
  OR shop_id IN (
    SELECT s.id
    FROM public.shops s
    JOIN public.sellers se ON se.id = s.seller_id
    WHERE se.user_id = (SELECT auth.uid())
  )
);