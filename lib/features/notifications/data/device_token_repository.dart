import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceTokenRepository {
 const DeviceTokenRepository(this.client); final SupabaseClient client;
 Future<void> register({required String token,required String platform}) async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  await client.from('notification_devices').upsert({'user_id':u.id,'platform':platform,'push_token':token,'active':true,'last_seen_at':DateTime.now().toUtc().toIso8601String()},onConflict:'user_id,push_token');
 }
 Future<void> deactivate(String token) async {
  final u=client.auth.currentUser;if(u==null)return;
  await client.from('notification_devices').update({'active':false}).eq('user_id',u.id).eq('push_token',token);
 }
}