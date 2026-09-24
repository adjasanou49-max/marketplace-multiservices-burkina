
create or replace function public.create_order_message(
 p_order_id uuid,p_body text,p_attachment_path text default null
) returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_conv uuid; v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if nullif(trim(coalesce(p_body,'')),'') is null and nullif(trim(coalesce(p_attachment_path,'')),'') is null then raise exception 'empty_message'; end if;
 if not exists(select 1 from public.orders where id=p_order_id and customer_id=v_user) and not exists(
   select 1 from public.order_groups og join public.shops s on s.id=og.shop_id join public.sellers se on se.id=s.seller_id where og.order_id=p_order_id and se.user_id=v_user
 ) then raise exception 'not_order_participant'; end if;

 select id into v_conv from public.conversations where order_id=p_order_id and type='ORDER' limit 1;
 if v_conv is null then
   insert into public.conversations(order_id,type) values(p_order_id,'ORDER') returning id into v_conv;
   insert into public.conversation_members(conversation_id,user_id)
   select v_conv,o.customer_id from public.orders o where o.id=p_order_id
   on conflict do nothing;
 end if;

 if not exists(select 1 from public.conversation_members where conversation_id=v_conv and user_id=v_user) then
   insert into public.conversation_members(conversation_id,user_id) values(v_conv,v_user) on conflict do nothing;
 end if;

 insert into public.messages(conversation_id,sender_id,body,attachment_path)
 values(v_conv,v_user,nullif(trim(p_body),''),nullif(trim(p_attachment_path),''))
 returning id into v_id;
 return v_id;
end $$;
revoke execute on function public.create_order_message(uuid,text,text) from public,anon,authenticated;
grant execute on function public.create_order_message(uuid,text,text) to service_role;
