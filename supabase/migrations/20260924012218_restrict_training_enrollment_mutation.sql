drop policy if exists training_enrollments_own on public.training_enrollments;

create policy training_enrollments_customer_read
on public.training_enrollments
for select
to authenticated
using (customer_id = auth.uid());
