begin;

grant execute on function private.is_admin() to authenticated;
grant execute on function private.has_role(public.user_role) to authenticated;

commit;