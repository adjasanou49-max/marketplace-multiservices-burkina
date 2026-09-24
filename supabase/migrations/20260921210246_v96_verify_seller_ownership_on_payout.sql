
do $patch$
declare
  def text;
begin
  select pg_get_functiondef(p.oid)
    into def
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='request_seller_payout_secure'
    and pg_get_function_identity_arguments(p.oid)
      = 'p_seller_id uuid, p_amount numeric, p_provider text';

  if def is null then
    raise exception 'request_seller_payout_secure definition not found';
  end if;

  def := replace(
    def,
    'begin
 if p_amount <= 0 then raise exception ''amount_invalid''; end if;',
    'begin
 if auth.uid() is null then raise exception ''not_authenticated''; end if;
 if not exists (
   select 1 from public.sellers
   where id = p_seller_id and user_id = auth.uid()
 ) then
   raise exception ''seller_not_owned'';
 end if;
 if p_amount <= 0 then raise exception ''amount_invalid''; end if;'
  );

  execute def;
end
$patch$;
