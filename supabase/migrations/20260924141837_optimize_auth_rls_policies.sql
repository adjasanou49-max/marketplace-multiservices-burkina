-- Mirrors the already-applied remote migration optimize_auth_rls_policies.
-- The change wraps auth.uid() in a scalar subquery so PostgreSQL can
-- evaluate it once per statement instead of once per row.

ALTER POLICY "accommodation_bookings_customer_read"
  ON public.accommodation_bookings
  USING (customer_id = (select auth.uid()));

ALTER POLICY "beauty_bookings_customer_read"
  ON public.beauty_bookings
  USING (customer_id = (select auth.uid()));

ALTER POLICY "courier_locations_read"
  ON public.courier_locations
  USING (
    (courier_id = (select auth.uid()))
    OR (
      id = (
        SELECT cl.id
        FROM public.courier_locations AS cl
        ORDER BY cl.recorded_at DESC, cl.id DESC
        LIMIT 1
      )
      AND EXISTS (
        SELECT 1
        FROM public.delivery_assignments AS da
        JOIN public.order_packages AS op ON op.id = da.package_id
        JOIN public.order_groups AS og ON og.id = op.order_group_id
        JOIN public.orders AS o ON o.id = og.order_id
        WHERE da.courier_id = courier_locations.courier_id
          AND o.customer_id = (select auth.uid())
          AND op.delivered_at IS NULL
      )
    )
  );

ALTER POLICY "digital_orders_customer_read"
  ON public.digital_orders
  USING (customer_id = (select auth.uid()));

ALTER POLICY "dispute_evidence_participant"
  ON public.dispute_evidence
  USING (
    (submitted_by = (select auth.uid()))
    AND (
      EXISTS (
        SELECT 1
        FROM public.disputes AS d
        WHERE d.id = dispute_evidence.dispute_id
          AND (
            d.opened_by = (select auth.uid())
            OR d.against_user_id = (select auth.uid())
          )
      )
      OR private.is_admin()
    )
  )
  WITH CHECK (
    (submitted_by = (select auth.uid()))
    AND (
      EXISTS (
        SELECT 1
        FROM public.disputes AS d
        WHERE d.id = dispute_evidence.dispute_id
          AND (
            d.opened_by = (select auth.uid())
            OR d.against_user_id = (select auth.uid())
          )
      )
      OR private.is_admin()
    )
  );

ALTER POLICY "event_bookings_customer_cancel_reserved"
  ON public.event_bookings
  USING (customer_id = (select auth.uid()) AND status = 'RESERVED');

ALTER POLICY "event_bookings_customer_read"
  ON public.event_bookings
  USING (customer_id = (select auth.uid()));

ALTER POLICY "group_buy_members_customer_read"
  ON public.group_buy_members
  USING (user_id = (select auth.uid()));

ALTER POLICY "home_service_requests_customer_read"
  ON public.home_service_requests
  USING (customer_id = (select auth.uid()));

ALTER POLICY "job_applications_applicant_read"
  ON public.job_applications
  USING (applicant_id = (select auth.uid()));

ALTER POLICY "mechanic_review_customer_manage"
  ON public.mechanic_reviews
  USING (
    (
      customer_id = (select auth.uid())
      AND EXISTS (
        SELECT 1
        FROM public.mechanic_requests AS mr
        JOIN public.mechanic_interventions AS mi ON mi.request_id = mr.id
        WHERE mr.id = mechanic_reviews.request_id
          AND mr.customer_id = (select auth.uid())
          AND mi.mechanic_id = mechanic_reviews.mechanic_id
          AND mi.completed_at IS NOT NULL
      )
    )
    OR private.is_admin()
  )
  WITH CHECK (
    (
      customer_id = (select auth.uid())
      AND EXISTS (
        SELECT 1
        FROM public.mechanic_requests AS mr
        JOIN public.mechanic_interventions AS mi ON mi.request_id = mr.id
        WHERE mr.id = mechanic_reviews.request_id
          AND mr.customer_id = (select auth.uid())
          AND mi.mechanic_id = mechanic_reviews.mechanic_id
          AND mi.completed_at IS NOT NULL
      )
    )
    OR private.is_admin()
  );

ALTER POLICY "products_read"
  ON public.products
  USING (
    (
      status = 'ACTIVE'::public.product_status
      AND (
        NOT is_expirable
        OR expiry_date IS NULL
        OR expiry_date >= CURRENT_DATE
      )
      AND EXISTS (
        SELECT 1
        FROM public.shops AS s
        WHERE s.id = products.shop_id
          AND s.status = 'ACTIVE'::public.shop_status
          AND s.verification_status = 'VERIFIED'::public.verification_status
      )
    )
    OR shop_id IN (
      SELECT s.id
      FROM public.shops AS s
      JOIN public.sellers AS se ON se.id = s.seller_id
      WHERE se.user_id = (select auth.uid())
    )
  );

ALTER POLICY "ride_requests_customer_read"
  ON public.ride_requests
  USING (customer_id = (select auth.uid()));

ALTER POLICY "training_enrollments_customer_read"
  ON public.training_enrollments
  USING (customer_id = (select auth.uid()));

ALTER POLICY "vehicle_rental_bookings_customer_read"
  ON public.vehicle_rental_bookings
  USING (customer_id = (select auth.uid()));
