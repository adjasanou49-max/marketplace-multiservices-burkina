create or replace function public.enforce_seller_document_review_fields()
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

  if new.verification_status is distinct from old.verification_status then
    raise exception 'document_verification_admin_only' using errcode='42501';
  end if;

  if new.reviewed_by is distinct from old.reviewed_by then
    raise exception 'document_review_metadata_admin_only' using errcode='42501';
  end if;

  if new.reviewed_at is distinct from old.reviewed_at then
    raise exception 'document_review_metadata_admin_only' using errcode='42501';
  end if;

  return new;
end;
$function$;

drop trigger if exists enforce_seller_document_review_fields
on public.seller_documents;

create trigger enforce_seller_document_review_fields
before update of verification_status,reviewed_by,reviewed_at
on public.seller_documents
for each row
execute function public.enforce_seller_document_review_fields();

alter table public.seller_documents
  alter column verification_status set default 'PENDING';
