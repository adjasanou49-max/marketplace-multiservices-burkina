
revoke all on function public.reserve_inventory(uuid,integer) from public, anon, authenticated;
revoke all on function public.release_inventory(uuid,integer) from public, anon, authenticated;
revoke all on function public.consume_reserved_inventory(uuid,integer) from public, anon, authenticated;

drop index if exists public.idx_reviews_shop_status;

do $$
declare
 r record;
 idx_name text;
 cols text;
begin
 for r in
   select c.conrelid::regclass as table_name,
          c.conname,
          string_agg(quote_ident(a.attname), ', ' order by k.ord) as col_list,
          string_agg(a.attname, '_' order by k.ord) as col_names
   from pg_constraint c
   cross join lateral unnest(c.conkey) with ordinality k(attnum,ord)
   join pg_attribute a on a.attrelid=c.conrelid and a.attnum=k.attnum
   where c.contype='f'
     and c.connamespace='public'::regnamespace
   group by c.conrelid,c.conname
 loop
   idx_name := 'idx_fk_' || regexp_replace(r.table_name::text,'[^a-zA-Z0-9]+','_','g') || '_' || left(md5(r.conname),8);
   execute format('create index if not exists %I on %s (%s)', idx_name, r.table_name, r.col_list);
 end loop;
end $$;
