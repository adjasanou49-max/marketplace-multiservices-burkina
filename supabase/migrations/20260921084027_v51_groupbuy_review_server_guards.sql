
create or replace function public.join_group_buy(p_group_buy_id uuid,p_quantity integer)
returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_group public.group_buys%rowtype; v_existing uuid; v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_quantity is null or p_quantity<1 then raise exception 'invalid_quantity'; end if;
 select * into v_group from public.group_buys where id=p_group_buy_id for update;
 if not found or v_group.status<>'OPEN' or v_group.starts_at>now() or v_group.ends_at<=now() then raise exception 'group_buy_unavailable'; end if;
 if v_group.current_quantity+p_quantity>v_group.target_quantity then raise exception 'group_buy_capacity_exceeded'; end if;
 select id into v_existing from public.group_buy_members where group_buy_id=p_group_buy_id and user_id=v_user for update;
 if v_existing is not null then
   update public.group_buy_members set quantity=quantity+p_quantity where id=v_existing returning id into v_id;
 else
   insert into public.group_buy_members(group_buy_id,user_id,quantity) values(p_group_buy_id,v_user,p_quantity) returning id into v_id;
 end if;
 update public.group_buys set current_quantity=current_quantity+p_quantity,status=case when current_quantity+p_quantity>=target_quantity then 'FILLED' else status end where id=p_group_buy_id;
 return v_id;
end $$;
revoke execute on function public.join_group_buy(uuid,integer) from public,anon,authenticated;
grant execute on function public.join_group_buy(uuid,integer) to service_role;

create or replace function public.create_review(
 p_product_id uuid,p_shop_id uuid,p_rating smallint,p_body text default null
) returns uuid language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_user uuid := (select auth.uid()); v_id uuid;
begin
 if v_user is null then raise exception 'not_authenticated'; end if;
 if p_rating<1 or p_rating>5 then raise exception 'invalid_rating'; end if;
 if p_product_id is null and p_shop_id is null then raise exception 'review_target_required'; end if;
 if not exists(
   select 1 from public.orders o join public.order_groups og on og.order_id=o.id join public.order_items oi on oi.order_group_id=og.id
   where o.customer_id=v_user and oi.product_id=p_product_id and o.status='DELIVERED'
 ) and p_product_id is not null then raise exception 'product_not_purchased'; end if;
 insert into public.reviews(customer_id,product_id,shop_id,rating,body,status)
 values(v_user,p_product_id,p_shop_id,p_rating,p_body,'PENDING') returning id into v_id;
 return v_id;
end $$;
revoke execute on function public.create_review(uuid,uuid,smallint,text) from public,anon,authenticated;
grant execute on function public.create_review(uuid,uuid,smallint,text) to service_role;
