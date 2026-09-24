
create index if not exists idx_shop_followers_user on public.shop_followers(user_id);
create index if not exists idx_product_favorites_user on public.product_favorites(user_id);
create index if not exists idx_recent_views_user on public.recent_views(user_id,viewed_at desc);
create index if not exists idx_notifications_user_unread on public.notifications(user_id,read_at,created_at desc);
create index if not exists idx_support_tickets_assigned on public.support_tickets(assigned_to,status);
create index if not exists idx_return_events_return on public.return_events(return_id,created_at desc);
create index if not exists idx_dispute_messages_dispute on public.dispute_messages(dispute_id,created_at desc);
create index if not exists idx_dispute_evidence_dispute on public.dispute_evidence(dispute_id,created_at desc);
create index if not exists idx_service_quotes_request on public.service_quotes(request_id,status);
create index if not exists idx_availability_provider on public.availability_schedules(provider_id,weekday);
create index if not exists idx_provider_time_off_provider on public.provider_time_off(provider_id,starts_at);
