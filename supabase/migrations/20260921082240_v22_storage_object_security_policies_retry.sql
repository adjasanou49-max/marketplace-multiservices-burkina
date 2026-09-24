
create policy "avatars_public_read"
on storage.objects for select to public
using (bucket_id='avatars');

create policy "avatars_owner_insert"
on storage.objects for insert to authenticated
with check (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid()::text));

create policy "avatars_owner_update"
on storage.objects for update to authenticated
using (bucket_id='avatars' and owner_id=(select auth.uid()::text))
with check (bucket_id='avatars' and owner_id=(select auth.uid()::text));

create policy "avatars_owner_delete"
on storage.objects for delete to authenticated
using (bucket_id='avatars' and owner_id=(select auth.uid()::text));

create policy "product_media_owner_insert"
on storage.objects for insert to authenticated
with check (
  bucket_id='product-media'
  and (storage.foldername(name))[1]='products'
  and exists (
    select 1 from public.products p
    join public.shops s on s.id=p.shop_id
    join public.sellers se on se.id=s.seller_id
    where p.id=(storage.foldername(storage.objects.name))[2]::uuid
      and se.user_id=(select auth.uid())
  )
);

create policy "product_media_owner_manage"
on storage.objects for update to authenticated
using (bucket_id='product-media' and owner_id=(select auth.uid()::text))
with check (bucket_id='product-media' and owner_id=(select auth.uid()::text));

create policy "product_media_owner_delete"
on storage.objects for delete to authenticated
using (bucket_id='product-media' and owner_id=(select auth.uid()::text));

create policy "product_media_customer_read"
on storage.objects for select to authenticated
using (
  bucket_id='product-media'
  and exists (
    select 1
    from public.product_images pi
    join public.products p on p.id=pi.product_id
    where pi.storage_path=storage.objects.name
      and p.status='ACTIVE'
      and not (p.is_expirable and p.expiry_date is not null and p.expiry_date < current_date)
  )
);

create policy "shop_media_owner_insert"
on storage.objects for insert to authenticated
with check (
  bucket_id='shop-media'
  and (storage.foldername(name))[1]='shops'
  and exists (
    select 1 from public.shops s
    join public.sellers se on se.id=s.seller_id
    where s.id=(storage.foldername(storage.objects.name))[2]::uuid
      and se.user_id=(select auth.uid())
  )
);

create policy "shop_media_owner_manage"
on storage.objects for update to authenticated
using (bucket_id='shop-media' and owner_id=(select auth.uid()::text))
with check (bucket_id='shop-media' and owner_id=(select auth.uid()::text));

create policy "shop_media_owner_delete"
on storage.objects for delete to authenticated
using (bucket_id='shop-media' and owner_id=(select auth.uid()::text));

create policy "documents_owner_insert"
on storage.objects for insert to authenticated
with check (
  bucket_id='documents'
  and (storage.foldername(name))[1]='sellers'
  and exists (
    select 1 from public.sellers se
    where se.id=(storage.foldername(storage.objects.name))[2]::uuid
      and se.user_id=(select auth.uid())
  )
);

create policy "documents_owner_read"
on storage.objects for select to authenticated
using (bucket_id='documents' and owner_id=(select auth.uid()::text));

create policy "documents_owner_manage"
on storage.objects for update to authenticated
using (bucket_id='documents' and owner_id=(select auth.uid()::text))
with check (bucket_id='documents' and owner_id=(select auth.uid()::text));

create policy "documents_owner_delete"
on storage.objects for delete to authenticated
using (bucket_id='documents' and owner_id=(select auth.uid()::text));
