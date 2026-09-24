drop policy if exists job_applications_own on public.job_applications;

create policy job_applications_applicant_read
on public.job_applications
for select
to authenticated
using (applicant_id = auth.uid());
