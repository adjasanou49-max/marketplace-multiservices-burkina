create or replace function public.join_group_buy(
  p_group_buy_id uuid,
  p_quantity integer default 1
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_user uuid := (select auth.uid());
  v_group public.group_buys%rowtype;
  v_existing uuid;
  v_id uuid;
begin
  if v_user is null then raise exception 'not_authenticated'; end if;
  if p_group_buy_id is null then raise exception 'group_buy_required'; end if;
  if p_quantity is null or p_quantity < 1 then raise exception 'invalid_quantity'; end if;

  select * into v_group
  from public.group_buys
  where id = p_group_buy_id
  for update;

  if not found
     or v_group.status <> 'OPEN'
     or v_group.starts_at > now()
     or v_group.ends_at <= now() then
    raise exception 'group_buy_unavailable';
  end if;

  select id into v_existing
  from public.group_buy_members
  where group_buy_id = p_group_buy_id
    and user_id = v_user
  for update;

  if v_group.current_quantity + p_quantity > v_group.target_quantity then
    raise exception 'group_buy_capacity_exceeded';
  end if;

  if v_existing is not null then
    update public.group_buy_members
    set quantity = quantity + p_quantity
    where id = v_existing
    returning id into v_id;
  else
    insert into public.group_buy_members(group_buy_id,user_id,quantity)
    values(p_group_buy_id,v_user,p_quantity)
    returning id into v_id;
  end if;

  update public.group_buys
  set current_quantity = current_quantity + p_quantity,
      status = case
        when current_quantity + p_quantity >= target_quantity then 'SUCCESS'
        else status
      end
  where id = p_group_buy_id;

  return v_id;
end;
$function$;

revoke all on function public.join_group_buy(uuid,integer) from public, anon;
grant execute on function public.join_group_buy(uuid,integer) to authenticated;
