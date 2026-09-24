
create index if not exists idx_cart_items_product on public.cart_items(product_id);
create index if not exists idx_inventory_movements_product_time on public.inventory_movements(product_id,created_at desc);
create index if not exists idx_order_items_group on public.order_items(order_group_id);
create index if not exists idx_order_packages_group_status on public.order_packages(order_group_id,status);
create index if not exists idx_delivery_assignments_package on public.delivery_assignments(package_id,status);
create index if not exists idx_conversation_members_user on public.conversation_members(user_id);
create index if not exists idx_messages_conversation_time on public.messages(conversation_id,created_at desc);
create index if not exists idx_reviews_shop_status on public.reviews(shop_id,status);
create index if not exists idx_sellers_user on public.sellers(user_id);
create index if not exists idx_shops_seller on public.shops(seller_id);
create index if not exists idx_products_shop_status on public.products(shop_id,status);
create index if not exists idx_products_category_status on public.products(category_id,status);
