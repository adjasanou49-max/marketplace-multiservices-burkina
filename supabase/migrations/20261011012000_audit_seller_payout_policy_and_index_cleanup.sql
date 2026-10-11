-- Audit remediation: consolidate identical payout read policies and remove a duplicate index.
-- Keeps the restrictive active-account guard and preserves seller/admin visibility.
BEGIN;

DROP POLICY IF EXISTS admin_payouts_read ON public.seller_payouts;
DROP POLICY IF EXISTS payouts_seller_read ON public.seller_payouts;

CREATE POLICY seller_payouts_owner_or_admin_read
  ON public.seller_payouts
  FOR SELECT
  TO authenticated
  USING (
    (SELECT private.is_admin())
    OR seller_id IN (
      SELECT s.id
      FROM public.sellers AS s
      WHERE s.user_id = (SELECT auth.uid())
    )
  );

DROP INDEX IF EXISTS public.uq_seller_payouts_provider_reference;

COMMIT;
