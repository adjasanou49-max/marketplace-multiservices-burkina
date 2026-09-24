create policy "product_media_anon_read"
on storage.objects
for select
to anon
using (
  bucket_id = 'product-media'
  and exists (
    select 1
    from public.product_images pi
    join public.products p on p.id = pi.product_id
    where pi.storage_path = storage.objects.name
      and p.status = 'ACTIVE'::public.product_status
      and not (
        p.is_expirable
        and p.expiry_date is not null
        and p.expiry_date < current_date
      )
  )
);

create policy "shop_media_anon_read"
on storage.objects
for select
to anon
using (
  bucket_id = 'shop-media'
  and exists (
    select 1
    from public.shops s
    where s.id = ((storage.foldername(storage.objects.name))[2])::uuid
      and s.status = 'ACTIVE'::public.shop_status
  )
);
