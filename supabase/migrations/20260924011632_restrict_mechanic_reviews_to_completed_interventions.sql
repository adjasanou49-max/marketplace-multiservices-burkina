alter policy mechanic_review_customer_manage
on public.mechanic_reviews
using (
  (
    customer_id = auth.uid()
    and exists (
      select 1
      from public.mechanic_requests mr
      join public.mechanic_interventions mi on mi.request_id = mr.id
      where mr.id = mechanic_reviews.request_id
        and mr.customer_id = auth.uid()
        and mi.mechanic_id = mechanic_reviews.mechanic_id
        and mi.completed_at is not null
    )
  )
  or private.is_admin()
)
with check (
  (
    customer_id = auth.uid()
    and exists (
      select 1
      from public.mechanic_requests mr
      join public.mechanic_interventions mi on mi.request_id = mr.id
      where mr.id = mechanic_reviews.request_id
        and mr.customer_id = auth.uid()
        and mi.mechanic_id = mechanic_reviews.mechanic_id
        and mi.completed_at is not null
    )
  )
  or private.is_admin()
);
