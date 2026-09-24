
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values
('avatars','avatars',true,5242880,array['image/jpeg','image/png','image/webp']),
('product-media','product-media',false,52428800,array['image/jpeg','image/png','image/webp','video/mp4']),
('shop-media','shop-media',false,52428800,array['image/jpeg','image/png','image/webp']),
('documents','documents',false,10485760,array['application/pdf','image/jpeg','image/png'])
on conflict (id) do update set
 public=excluded.public,
 file_size_limit=excluded.file_size_limit,
 allowed_mime_types=excluded.allowed_mime_types;
