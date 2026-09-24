REVOKE EXECUTE ON FUNCTION public.admin_set_account_status(uuid, public.account_status, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_set_product_status(uuid, public.product_status, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_admin_actor() FROM anon;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text, boolean) FROM PUBLIC;