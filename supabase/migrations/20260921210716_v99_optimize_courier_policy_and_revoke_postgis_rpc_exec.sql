
drop policy if exists courier_locations_courier_insert on public.courier_locations;

create policy courier_locations_courier_insert
on public.courier_locations
for insert
to authenticated
with check (
  courier_id = (select auth.uid())
  and (select private.has_role('COURIER'::public.user_role))
);

revoke execute on function public.st_estimatedextent(text,text) from public;
revoke execute on function public.st_estimatedextent(text,text,text) from public;
revoke execute on function public.st_estimatedextent(text,text,text,boolean) from public;
revoke execute on function public.st_estimatedextent(text,text) from anon,authenticated;
revoke execute on function public.st_estimatedextent(text,text,text) from anon,authenticated;
revoke execute on function public.st_estimatedextent(text,text,text,boolean) from anon,authenticated;
