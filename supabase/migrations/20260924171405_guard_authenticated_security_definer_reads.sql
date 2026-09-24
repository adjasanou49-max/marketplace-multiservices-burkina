begin;

create or replace function public.get_customer_payment_status(p_order_id uuid)
returns table(
  payment_id uuid,
  provider text,
  provider_reference text,
  amount numeric,
  currency text,
  status public.payment_status,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  perform private.require_active_account();
  return query
  select
    p.id,
    p.provider,
    p.provider_reference,
    p.amount,
    p.currency,
    p.status,
    p.created_at,
    p.updated_at
  from public.payments p
  join public.orders o on o.id=p.order_id
  where p.order_id=p_order_id
    and o.customer_id=(select auth.uid())
  order by p.created_at desc
  limit 1;
end;
$function$;

create or replace function public.get_customer_refunds(p_order_id uuid)
returns table(
  refund_id uuid,
  amount numeric,
  currency text,
  reason text,
  status text,
  provider_reference text,
  created_at timestamptz,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  perform private.require_active_account();
  return query
  select
    r.id,
    r.amount,
    r.currency,
    r.reason,
    r.status,
    r.provider_reference,
    r.created_at,
    r.completed_at
  from public.refunds r
  join public.orders o on o.id=r.order_id
  where r.order_id=p_order_id
    and o.customer_id=(select auth.uid())
  order by r.created_at desc;
end;
$function$;

create or replace function public.my_favorite_products(p_limit integer default 50)
returns table(
  product_id uuid,
  name text,
  price numeric,
  currency text,
  shop_id uuid,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  perform private.require_active_account();
  return query
  select p.id,p.name,p.price,'XOF'::text,p.shop_id,pf.created_at
  from public.product_favorites pf
  join public.products p on p.id=pf.product_id
  where pf.user_id=(select auth.uid())
    and p.status='ACTIVE'
  order by pf.created_at desc
  limit greatest(1,least(coalesce(p_limit,50),100));
end;
$function$;

create or replace function public.my_followed_shops(p_limit integer default 50)
returns table(
  shop_id uuid,
  name text,
  description text,
  logo_url text,
  cover_url text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  perform private.require_active_account();
  return query
  select s.id,s.name,s.description,s.logo_url,s.cover_url,sf.created_at
  from public.shop_followers sf
  join public.shops s on s.id=sf.shop_id
  where sf.user_id=(select auth.uid())
    and s.status='ACTIVE'
  order by sf.created_at desc
  limit greatest(1,least(coalesce(p_limit,50),100));
end;
$function$;

commit;