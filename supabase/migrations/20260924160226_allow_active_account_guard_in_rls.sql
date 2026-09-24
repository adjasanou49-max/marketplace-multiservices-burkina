begin;

grant execute on function private.is_active_account() to authenticated;

commit;