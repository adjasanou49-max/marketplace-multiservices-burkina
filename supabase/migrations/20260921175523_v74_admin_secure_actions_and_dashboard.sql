create or replace function public.is_admin_actor()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
 select exists (
   select 1 from public.user_roles
   where user_id = auth.uid()
     and role in ('ADMIN'::public.user_role,'SUPER_ADMIN'::public.user_role,'MODERATOR'::public.user_role)
 );
$$;

revoke all on function public.is_admin_actor() from public;
grant execute on function public.is_admin_actor() to authenticated;

create or replace function public.get_admin_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
begin
 if not public.is_admin_actor() then raise exception 'admin access required' using errcode='42501'; end if;
 return jsonb_build_object(
  'users',(select count(*) from public.profiles),
  'sellers',(select count(*) from public.sellers),
  'shops',(select count(*) from public.shops),
  'active_products',(select count(*) from public.products where status='ACTIVE'),
  'orders',(select count(*) from public.orders),
  'open_support',(select count(*) from public.support_tickets where status not in ('RESOLVED','CLOSED')),
  'fraud_reports',(select count(*) from public.fraud_reports where status not in ('RESOLVED','CLOSED'))
 );
end;
$$;

create or replace function public.admin_set_account_status(p_user_id uuid,p_status public.account_status,p_reason text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
 if not public.is_admin_actor() then raise exception 'admin access required' using errcode='42501'; end if;
 if p_user_id = auth.uid() and p_status in ('SUSPENDED','BLOCKED') then raise exception 'cannot disable current admin account' using errcode='22023'; end if;
 update public.profiles set status=p_status,updated_at=now() where id=p_user_id;
 if not found then raise exception 'user not found' using errcode='P0002'; end if;
 insert into public.account_actions(target_user_id,actor_id,action,reason)
 values(p_user_id,auth.uid(),p_status::text,p_reason);
end;
$$;

revoke all on function public.admin_set_account_status(uuid,public.account_status,text) from public;
grant execute on function public.admin_set_account_status(uuid,public.account_status,text) to authenticated;

create or replace function public.admin_set_product_status(p_product_id uuid,p_status public.product_status,p_reason text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
 if not public.is_admin_actor() then raise exception 'admin access required' using errcode='42501'; end if;
 update public.products set status=p_status,updated_at=now() where id=p_product_id;
 if not found then raise exception 'product not found' using errcode='P0002'; end if;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata)
 values(auth.uid(),'ADMIN_PRODUCT_STATUS','product',p_product_id,jsonb_build_object('status',p_status::text,'reason',p_reason));
end;
$$;

revoke all on function public.admin_set_product_status(uuid,public.product_status,text) from public;
grant execute on function public.admin_set_product_status(uuid,public.product_status,text) to authenticated;