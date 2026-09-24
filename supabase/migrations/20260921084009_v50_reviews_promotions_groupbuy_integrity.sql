
alter table public.reviews add constraint reviews_rating_range check(rating between 1 and 5);
alter table public.coupons add constraint coupons_discount_nonnegative check(discount_value>=0 and min_order_amount>=0 and used_count>=0);
alter table public.coupons add constraint coupons_dates_valid check(ends_at>starts_at);
alter table public.coupons add constraint coupons_max_uses_valid check(max_uses is null or max_uses>0);
alter table public.promotions add constraint promotions_value_nonnegative check(value>=0);
alter table public.promotions add constraint promotions_dates_valid check(ends_at>starts_at);
alter table public.group_buys add constraint group_buy_quantities_valid check(target_quantity>0 and current_quantity>=0 and current_quantity<=target_quantity);
alter table public.group_buys add constraint group_buy_price_nonnegative check(group_price>=0);
alter table public.group_buys add constraint group_buy_dates_valid check(ends_at>starts_at);
alter table public.group_buy_members add constraint group_buy_member_quantity_positive check(quantity>0);

create unique index if not exists uq_product_favorite_user_product on public.product_favorites(user_id,product_id);
create unique index if not exists uq_shop_follower_user_shop on public.shop_followers(user_id,shop_id);
create unique index if not exists uq_review_customer_product_shop on public.reviews(customer_id,product_id,shop_id);
create index if not exists idx_reviews_product_status_created on public.reviews(product_id,status,created_at desc);
create index if not exists idx_reviews_shop_status_created on public.reviews(shop_id,status,created_at desc);
create index if not exists idx_promotions_active_dates on public.promotions(active,starts_at,ends_at);
create index if not exists idx_coupons_code_active_dates on public.coupons(code,active,starts_at,ends_at);
create index if not exists idx_group_buys_status_dates on public.group_buys(status,starts_at,ends_at);
create index if not exists idx_group_buy_members_group on public.group_buy_members(group_buy_id);
