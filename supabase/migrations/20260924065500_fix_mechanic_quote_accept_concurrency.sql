create or replace function public.accept_mechanic_quote(
  p_quote_id uuid
)
returns uuid
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_user uuid := auth.uid();
  v_request uuid;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'not_authenticated';
  end if;

  select q.request_id
    into v_request
  from public.mechanic_quotes q
  where q.id = p_quote_id
    and q.status = 'PENDING'
  for update;

  if v_request is null then
    raise exception 'quote_not_available';
  end if;

  perform 1
  from public.mechanic_requests mr
  where mr.id = v_request
    and mr.customer_id = v_user
    and mr.status in ('OPEN','REQUESTED','QUOTED')
  for update;

  if not found then
    raise exception 'not_authorized';
  end if;

  update public.mechanic_quotes
  set status = 'ACCEPTED'
  where id = p_quote_id
    and status = 'PENDING'
  returning id into v_id;

  if v_id is null then
    raise exception 'quote_not_available';
  end if;

  update public.mechanic_requests
  set status = 'ACCEPTED'
  where id = v_request;

  update public.mechanic_quotes
  set status = 'REJECTED'
  where request_id = v_request
    and id <> p_quote_id
    and status = 'PENDING';

  return v_id;
end;
$function$;
