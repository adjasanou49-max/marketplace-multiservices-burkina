-- Administrators must be able to inspect all products, including products
-- awaiting approval, without weakening public marketplace visibility.
alter policy products_read
on public.products
using (
  public.is_admin_actor()
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
    where se.user_id = auth.uid()
  )
);
