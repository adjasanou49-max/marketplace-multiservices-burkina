alter policy products_read
on public.products
using (
  (
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

alter policy product_media_customer_read
on storage.objects
using (
  bucket_id = 'product-media'
  and exists (
    select 1
    from public.product_images pi
    join public.products p on p.id = pi.product_id
    join public.shops s on s.id = p.shop_id
    where pi.storage_path = storage.objects.name
      and p.status = 'ACTIVE'::public.product_status
      and s.status = 'ACTIVE'::public.shop_status
      and s.verification_status = 'VERIFIED'::public.verification_status
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);

alter policy product_media_anon_read
on storage.objects
using (
  bucket_id = 'product-media'
  and exists (
    select 1
    from public.product_images pi
    join public.products p on p.id = pi.product_id
    join public.shops s on s.id = p.shop_id
    where pi.storage_path = storage.objects.name
      and p.status = 'ACTIVE'::public.product_status
      and s.status = 'ACTIVE'::public.shop_status
      and s.verification_status = 'VERIFIED'::public.verification_status
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);
