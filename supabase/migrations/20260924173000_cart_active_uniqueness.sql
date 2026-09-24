-- Guarantee at most one active cart per customer.
-- Existing duplicates are resolved before the unique partial index is created.
DO $$
DECLARE
  duplicate RECORD;
  keeper UUID;
BEGIN
  FOR duplicate IN
    SELECT customer_id
    FROM carts
    WHERE status = 'ACTIVE'
    GROUP BY customer_id
    HAVING COUNT(*) > 1
  LOOP
    SELECT id
      INTO keeper
    FROM carts
    WHERE customer_id = duplicate.customer_id
      AND status = 'ACTIVE'
    ORDER BY created_at DESC NULLS LAST, id DESC
    LIMIT 1;

    -- Merge cart items into the newest active cart.
    INSERT INTO cart_items (cart_id, product_id, quantity, unit_price)
    SELECT
      keeper,
      ci.product_id,
      SUM(ci.quantity),
      MAX(ci.unit_price)
    FROM cart_items ci
    JOIN carts c ON c.id = ci.cart_id
    WHERE c.customer_id = duplicate.customer_id
      AND c.status = 'ACTIVE'
      AND ci.cart_id <> keeper
    GROUP BY ci.product_id
    ON CONFLICT (cart_id, product_id)
    DO UPDATE SET
      quantity = cart_items.quantity + EXCLUDED.quantity,
      unit_price = EXCLUDED.unit_price;

    DELETE FROM cart_items ci
    USING carts c
    WHERE ci.cart_id = c.id
      AND c.customer_id = duplicate.customer_id
      AND c.status = 'ACTIVE'
      AND ci.cart_id <> keeper;

    UPDATE carts
    SET status = 'MERGED'
    WHERE customer_id = duplicate.customer_id
      AND status = 'ACTIVE'
      AND id <> keeper;
  END LOOP;
END
$$;

CREATE UNIQUE INDEX IF NOT EXISTS carts_one_active_per_customer_idx
  ON carts (customer_id)
  WHERE status = 'ACTIVE';
