
drop policy if exists admin_account_actions_read on public.account_actions;
drop policy if exists account_actions_target_read on public.account_actions;
create policy account_actions_read on public.account_actions
for select to authenticated
using ((select private.is_admin()) or target_user_id=(select auth.uid()));

drop policy if exists admin_fraud_reports on public.fraud_reports;
drop policy if exists fraud_reports_own_read on public.fraud_reports;
create policy fraud_reports_read on public.fraud_reports
for select to authenticated
using ((select private.is_admin()) or reporter_id=(select auth.uid()));

drop policy if exists admin_security_events on public.security_events;
drop policy if exists security_events_own_read on public.security_events;
create policy security_events_read on public.security_events
for select to authenticated
using ((select private.is_admin()) or user_id=(select auth.uid()));

drop policy if exists admin_change_log_admin_read on public.admin_change_log;
create policy admin_change_log_read on public.admin_change_log
for select to authenticated
using ((select private.is_admin()));

drop policy if exists admin_settings_read on public.platform_settings;
create policy admin_settings_read on public.platform_settings
for select to authenticated
using ((select private.is_admin()));

drop policy if exists admin_flags_read on public.feature_flags;
create policy admin_flags_read on public.feature_flags
for select to authenticated
using ((select private.is_admin()));
