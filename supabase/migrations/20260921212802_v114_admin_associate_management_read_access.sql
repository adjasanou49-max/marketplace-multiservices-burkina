
drop policy if exists company_admin_read on public.company;
create policy company_admin_read
on public.company for select to authenticated
using ((select private.is_admin()));

drop policy if exists share_classes_admin_read on public.share_classes;
create policy share_classes_admin_read
on public.share_classes for select to authenticated
using ((select private.is_admin()));

drop policy if exists profiles_admin_read on public.profiles;
create policy profiles_admin_read
on public.profiles for select to authenticated
using ((select private.is_admin()));
