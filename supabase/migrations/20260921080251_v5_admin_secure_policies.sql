
create policy admin_settings_read on public.platform_settings
for select to authenticated using ((select private.is_admin()));
create policy admin_flags_read on public.feature_flags
for select to authenticated using ((select private.is_admin()));
create policy admin_security_events on public.security_events
for select to authenticated using ((select private.is_admin()));
create policy admin_fraud_reports on public.fraud_reports
for select to authenticated using ((select private.is_admin()) or reporter_id=auth.uid());
create policy admin_account_actions on public.account_actions
for insert to authenticated with check ((select private.is_admin()) and actor_id=auth.uid());
create policy admin_account_actions_read on public.account_actions
for select to authenticated using ((select private.is_admin()) or target_user_id=auth.uid());
