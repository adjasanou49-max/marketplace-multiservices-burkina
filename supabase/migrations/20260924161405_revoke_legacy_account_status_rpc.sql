begin;

revoke all on function public.set_account_status(uuid,text,text) from public, anon, authenticated;

commit;