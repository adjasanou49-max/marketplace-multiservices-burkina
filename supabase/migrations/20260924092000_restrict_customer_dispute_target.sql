create or replace function public.open_dispute(
  p_order_id uuid,
  p_reason text,
  p_against_user_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_user uuid := auth.uid();
  v_is_admin boolean := public.is_admin();
  v_id uuid;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  if nullif(trim(p_reason),'') is null then
    raise exception 'reason_required';
  end if;

  if not exists (
    select 1
    from public.orders
    where id = p_order_id
      and customer_id = v_user
  ) and not v_is_admin then
    raise exception 'not_authorized';
  end if;

  if not v_is_admin and p_against_user_id is not null then
    raise exception 'against_user_not_allowed';
  end if;

  if exists (
    select 1
    from public.disputes
    where order_id=p_order_id
      and status in ('OPEN','IN_REVIEW','ESCALATED')
  ) then
    raise exception 'dispute_already_open';
  end if;

  insert into public.disputes(
    order_id,
    opened_by,
    against_user_id,
    reason,
    status
  )
  values(
    p_order_id,
    v_user,
    case when v_is_admin then p_against_user_id else null end,
    trim(p_reason),
    'OPEN'
  )
  returning id into v_id;

  return v_id;
end
$function$;
