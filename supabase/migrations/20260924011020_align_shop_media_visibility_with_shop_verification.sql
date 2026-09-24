alter policy shop_media_customer_read
on storage.objects
using (
  bucket_id = 'shop-media'
  and exists (
    select 1
    from public.shops s
    where s.id = ((storage.foldername(storage.objects.name))[2])::uuid
      and s.status = 'ACTIVE'::public.shop_status
      and s.verification_status = 'VERIFIED'::public.verification_status
  )
);

alter policy shop_media_anon_read
on storage.objects
using (
  bucket_id = 'shop-media'
  and exists (
    select 1
    from public.shops s
    where s.id = ((storage.foldername(storage.objects.name))[2])::uuid
      and s.status = 'ACTIVE'::public.shop_status
      and s.verification_status = 'VERIFIED'::public.verification_status
  )
);
