begin;

revoke select on table public.transport_companies from anon;
grant select (
  id,
  name,
  phone,
  verification_status,
  active,
  created_at
) on table public.transport_companies to anon;

commit;