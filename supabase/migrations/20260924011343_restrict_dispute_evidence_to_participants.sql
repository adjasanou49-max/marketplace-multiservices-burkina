alter policy dispute_evidence_participant
on public.dispute_evidence
using (
  submitted_by = auth.uid()
  and (
    exists (
      select 1
      from public.disputes d
      where d.id = dispute_evidence.dispute_id
        and (
          d.opened_by = auth.uid()
          or d.against_user_id = auth.uid()
        )
    )
    or private.is_admin()
  )
)
with check (
  submitted_by = auth.uid()
  and (
    exists (
      select 1
      from public.disputes d
      where d.id = dispute_evidence.dispute_id
        and (
          d.opened_by = auth.uid()
          or d.against_user_id = auth.uid()
        )
    )
    or private.is_admin()
  )
);
