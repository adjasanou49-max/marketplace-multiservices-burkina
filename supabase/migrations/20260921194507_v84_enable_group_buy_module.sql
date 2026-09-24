insert into public.marketplace_modules (key,label,route,icon_name,enabled,sort_order)
values ('group_buy','Achats groupés','/group-buy','groups',true,55)
on conflict (key) do update
set label=excluded.label,route=excluded.route,icon_name=excluded.icon_name,enabled=true,sort_order=excluded.sort_order,updated_at=now();