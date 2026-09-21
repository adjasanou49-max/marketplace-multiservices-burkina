import 'package:supabase_flutter/supabase_flutter.dart';
class AdminAccountRepository {
 const AdminAccountRepository(this.client); final SupabaseClient client;
 Future<void> setStatus(String userId,String status,String reason) async {
  await client.rpc('admin_set_account_status',params:{'p_user_id':userId,'p_status':status,'p_reason':reason});
 }
 Future<void> suspend(String userId,String reason)=>setStatus(userId,'SUSPENDED',reason);
 Future<void> block(String userId,String reason)=>setStatus(userId,'BLOCKED',reason);
 Future<void> reactivate(String userId,String reason)=>setStatus(userId,'ACTIVE',reason);
}