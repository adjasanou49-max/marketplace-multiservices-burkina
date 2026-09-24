
drop policy if exists reviews_customer_insert on public.reviews;
drop policy if exists reviews_owner_update on public.reviews;
drop policy if exists returns_customer_insert on public.returns;
drop policy if exists disputes_participant_insert on public.disputes;
drop policy if exists coupon_usage_insert on public.coupon_usage;

revoke all on function public.create_review(uuid,uuid,smallint,text) from public,anon;
revoke all on function public.create_review(uuid,uuid,integer,text) from public,anon;
revoke all on function public.open_return(uuid,uuid,text) from public,anon;
revoke all on function public.open_dispute(uuid,text,uuid) from public,anon;

grant execute on function public.create_review(uuid,uuid,smallint,text) to authenticated;
grant execute on function public.create_review(uuid,uuid,integer,text) to authenticated;
grant execute on function public.open_return(uuid,uuid,text) to authenticated;
grant execute on function public.open_dispute(uuid,text,uuid) to authenticated;
