begin;

alter default privileges for role postgres in schema public
  revoke select, insert, update, delete, truncate, references, trigger
  on tables from anon, authenticated;

alter default privileges for role postgres in schema public
  revoke usage, select, update
  on sequences from anon, authenticated;

alter default privileges for role postgres in schema public
  revoke execute
  on functions from anon, authenticated;

alter default privileges for role postgres in schema public
  grant select, insert, update, delete, truncate, references, trigger
  on tables to service_role;

alter default privileges for role postgres in schema public
  grant usage, select, update
  on sequences to service_role;

alter default privileges for role postgres in schema public
  grant execute
  on functions to service_role;

commit;