create or replace function public.enforce_product_status_transition()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  if auth.uid() is null then
    return new;
  end if;

  if public.is_admin_actor() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.status = 'ACTIVE'::public.product_status then
      raise exception 'admin_approval_required' using errcode='42501';
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE'
     and new.status = 'ACTIVE'::public.product_status
     and old.status <> 'ACTIVE'::public.product_status then
    raise exception 'admin_approval_required' using errcode='42501';
  end if;

  return new;
end;
$function$;

drop trigger if exists enforce_product_status_transition on public.products;

create trigger enforce_product_status_transition
before insert or update of status on public.products
for each row
execute function public.enforce_product_status_transition();
