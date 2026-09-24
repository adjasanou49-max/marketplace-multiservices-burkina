
drop policy if exists company_admin_read on public.company;
drop policy if exists company_member_read on public.company;
create policy company_select
on public.company for select to authenticated
using (
  (select private.is_admin())
  or id in (
    select cm.company_id
    from public.company_members cm
    where cm.user_id=(select auth.uid())
  )
);

drop policy if exists profiles_admin_read on public.profiles;
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select
on public.profiles for select to authenticated
using (
  (select private.is_admin())
  or id=(select auth.uid())
);

drop policy if exists share_classes_admin_read on public.share_classes;
drop policy if exists share_classes_company_member_read on public.share_classes;
create policy share_classes_select
on public.share_classes for select to authenticated
using (
  (select private.is_admin())
  or company_id in (
    select cm.company_id
    from public.company_members cm
    where cm.user_id=(select auth.uid())
  )
);

drop policy if exists coupons_public_read on public.coupons;
drop policy if exists coupons_seller_read on public.coupons;
create policy coupons_select
on public.coupons for select to anon,authenticated
using (
  (
    active=true
    and now() >= starts_at
    and now() <= ends_at
  )
  or seller_id in (
    select s.id
    from public.sellers s
    where s.user_id=(select auth.uid())
  )
);

drop policy if exists promotions_public_read on public.promotions;
drop policy if exists promotions_seller_read on public.promotions;
create policy promotions_select
on public.promotions for select to anon,authenticated
using (
  (
    active=true
    and now() >= starts_at
    and now() <= ends_at
  )
  or seller_id in (
    select s.id
    from public.sellers s
    where s.user_id=(select auth.uid())
  )
);
