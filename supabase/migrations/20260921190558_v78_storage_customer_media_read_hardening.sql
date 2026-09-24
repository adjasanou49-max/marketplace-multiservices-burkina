DROP POLICY IF EXISTS "v64_product_media_read" ON storage.objects;
DROP POLICY IF EXISTS "v64_shop_media_read" ON storage.objects;

CREATE POLICY "shop_media_customer_read"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'shop-media'
  AND EXISTS (
    SELECT 1
    FROM public.shops s
    WHERE s.id = (storage.foldername(objects.name))[2]::uuid
      AND s.status = 'ACTIVE'::public.shop_status
  )
);