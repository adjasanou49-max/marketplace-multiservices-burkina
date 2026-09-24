update public.marketplace_modules
set enabled = true, updated_at = now()
where key in ('restaurants','transport','mechanics','expiry','promotions','follows','services');