
create or replace function public.set_account_status(
 p_target_user uuid,
 p_action text,
 p_reason text default null
) returns boolean
language plpgsql security definer
set search_path=pg_catalog,public
as $$
declare v_actor uuid := (select auth.uid()); v_status public.account_status;
begin
 if v_actor is null or not public.is_admin() then raise exception 'admin_required'; end if;
 if p_target_user is null then raise exception 'invalid_user'; end if;
 if p_target_user=v_actor then raise exception 'cannot_modify_self'; end if;

 case upper(trim(p_action))
  when 'SUSPEND' then v_status:='SUSPENDED';
  when 'BLOCK' then v_status:='BLOCKED';
  when 'REACTIVATE' then v_status:='ACTIVE';
  else raise exception 'invalid_account_action';
 end case;

 update public.profiles set status=v_status where id=p_target_user;
 if not found then raise exception 'user_not_found'; end if;

 insert into public.account_actions(target_user_id,actor_id,action,reason)
 values(p_target_user,v_actor,upper(trim(p_action)),p_reason);

 insert into public.admin_change_log(actor_id,entity_type,entity_id,action,after_data)
 values(v_actor,'profile',p_target_user,upper(trim(p_action)),
        jsonb_build_object('status',v_status::text,'reason',p_reason));

 return true;
end $$;

revoke execute on function public.set_account_status(uuid,text,text) from public,anon,authenticated;
grant execute on function public.set_account_status(uuid,text,text) to authenticated;

alter table public.fraud_events add constraint fraud_events_risk_score_range check (risk_score is null or risk_score between 0 and 100);
alter table public.incidents add constraint incidents_description_nonempty check (length(trim(description)) > 0);
create index if not exists idx_account_actions_target_created on public.account_actions(target_user_id,created_at desc);
create index if not exists idx_security_events_user_created on public.security_events(user_id,created_at desc);
create index if not exists idx_fraud_events_entity_created on public.fraud_events(entity_type,entity_id,created_at desc);
