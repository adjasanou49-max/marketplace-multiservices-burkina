begin;

revoke select on table public.reviews from anon, authenticated;
grant select (
  id,
  product_id,
  shop_id,
  rating,
  body,
  status,
  created_at
) on table public.reviews to anon, authenticated;

commit;