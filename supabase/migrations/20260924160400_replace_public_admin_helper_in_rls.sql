begin;

alter policy products_read
on public.products
using (
  private.is_admin()
  or (
    status = 'ACTIVE'::public.product_status
    and (
      not is_expirable
      or expiry_date is null
      or expiry_date >= current_date
    )
    and exists (
      select 1
      from public.shops s
      where s.id = products.shop_id
        and s.status = 'ACTIVE'::public.shop_status
        and s.verification_status = 'VERIFIED'::public.verification_status
    )
  )
  or shop_id in (
    select s.id
    from public.shops s
    join public.sellers se on se.id = s.seller_id
    where se.user_id = (select auth.uid())
  )
);

revoke all on function public.is_admin_actor() from public, anon, authenticated;

commit;