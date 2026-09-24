create or replace function public.product_expiry_status(p_expiry_date date) returns public.expiry_status language sql stable as $$ select case when p_expiry_date is null then 'NORMAL'::public.expiry_status when p_expiry_date < current_date then 'EXPIRED'::public.expiry_status when p_expiry_date <= current_date + 30 then 'EXPIRING_SOON'::public.expiry_status else 'NORMAL'::public.expiry_status end $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name',new.email)); insert into public.user_roles(user_id,role) values(new.id,'CUSTOMER'); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create policy profiles_select_own on public.profiles for select using (id=auth.uid());
create policy profiles_update_own on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
create policy categories_public_read on public.categories for select using (is_active=true);
create policy category_types_public_read on public.category_types for select using (is_active=true);
create policy shops_public_read on public.shops for select using (status='ACTIVE' and verification_status='VERIFIED');
create policy products_public_read on public.products for select using (status='ACTIVE' and (not is_expirable or expiry_date is null or expiry_date >= current_date));
create policy product_images_public_read on public.product_images for select using (exists(select 1 from public.products p where p.id=product_id and p.status='ACTIVE'));
create policy product_variants_public_read on public.product_variants for select using (exists(select 1 from public.products p where p.id=product_id and p.status='ACTIVE'));
create policy reviews_public_read on public.reviews for select using (status='PUBLISHED');
create policy carts_owner_all on public.carts for all using (customer_id=auth.uid()) with check (customer_id=auth.uid());
create policy cart_items_owner_all on public.cart_items for all using (exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=auth.uid())) with check (exists(select 1 from public.carts c where c.id=cart_id and c.customer_id=auth.uid()));
create policy orders_customer_read on public.orders for select using (customer_id=auth.uid());
create policy messages_member_read on public.messages for select using (exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_id and cm.user_id=auth.uid()));
create policy messages_member_insert on public.messages for insert with check (sender_id=auth.uid() and exists(select 1 from public.conversation_members cm where cm.conversation_id=conversation_id and cm.user_id=auth.uid()));
create policy conversation_members_self_read on public.conversation_members for select using (user_id=auth.uid());
create policy conversations_member_read on public.conversations for select using (exists(select 1 from public.conversation_members cm where cm.conversation_id=id and cm.user_id=auth.uid()));
create policy reviews_customer_insert on public.reviews for insert with check (customer_id=auth.uid());
create policy audit_logs_no_client_access on public.audit_logs for select using (false);

create or replace function public.is_expiring_soon(p_expiry_date date) returns boolean language sql stable as $$ select public.product_expiry_status(p_expiry_date)='EXPIRING_SOON' $$;