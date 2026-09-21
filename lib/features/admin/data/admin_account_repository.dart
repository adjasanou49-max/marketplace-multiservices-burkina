import 'package:supabase_flutter/supabase_flutter.dart';
class AdminAccountRepository {
 const AdminAccountRepository(this.client); final SupabaseClient client;
 Future<void> suspend(String userId,String reason) async { await client.rpc('suspend_account',params:{'p_user_id':userId,'p_reason':reason}); }
 Future<void> block(String userId,String reason) async { await client.rpc('block_account',params:{'p_user_id':userId,'p_reason':reason}); }
 Future<void> reactivate(String userId,String reason) async { await client.rpc('reactivate_account',params:{'p_user_id':userId,'p_reason':reason}); }
}