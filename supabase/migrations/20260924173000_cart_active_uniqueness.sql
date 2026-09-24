-- Serialize active-cart creation per customer and reject concurrent duplicates.
CREATE OR REPLACE FUNCTION public.enforce_one_active_cart()
RETURNS trigger
LANGUAGE plpgsql
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
