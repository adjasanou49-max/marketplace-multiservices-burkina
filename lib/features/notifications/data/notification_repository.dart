import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  const NotificationRepository(this.client);
  final SupabaseClient client;

  Future<List<Map<String,dynamic>>> mine({int limit=50}) async {
    final u=client.auth.currentUser;
    if(u==null) throw StateError('Utilisateur non authentifié');
    final rows=await client.from('notifications').select().eq('user_id',u.id).order('created_at',ascending:false).limit(limit);
    return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
}