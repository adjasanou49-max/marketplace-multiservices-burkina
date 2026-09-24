
drop policy if exists "avatars_authenticated_read" on storage.objects;
drop policy if exists "avatars_own_insert" on storage.objects;
drop policy if exists "avatars_own_update" on storage.objects;
drop policy if exists "avatars_own_delete" on storage.objects;
create policy "v64_avatars_authenticated_read" on storage.objects for select to authenticated using (bucket_id='avatars');
create policy "v64_avatars_own_insert" on storage.objects for insert to authenticated with check (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "v64_avatars_own_update" on storage.objects for update to authenticated using (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text) with check (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "v64_avatars_own_delete" on storage.objects for delete to authenticated using (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "v64_product_media_read" on storage.objects for select to authenticated using (bucket_id='product-media');
create policy "v64_shop_media_read" on storage.objects for select to authenticated using (bucket_id='shop-media');
