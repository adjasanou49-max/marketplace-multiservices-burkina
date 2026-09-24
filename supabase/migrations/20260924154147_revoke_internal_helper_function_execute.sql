begin;

revoke all on function public.normalize_shop_name(text) from public, anon, authenticated;
revoke all on function public.product_expiry_status(date) from public, anon, authenticated;
revoke all on function public.is_expiring_soon(date) from public, anon, authenticated;
revoke all on function public.prevent_expired_product_activation() from public, anon, authenticated;
revoke all on function public.enforce_one_active_cart() from public, anon, authenticated;
revoke all on function public.set_shop_normalized_name() from public, anon, authenticated;
revoke all on function public.validate_order_totals() from public, anon, authenticated;

commit;