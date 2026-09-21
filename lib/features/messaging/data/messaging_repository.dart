import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingRepository {
 const MessagingRepository(this.client);
 final SupabaseClient client;

 Future<List<Map<String,dynamic>>> conversations() async {
  final u=client.auth.currentUser;
  if(u==null) throw StateError('Utilisateur non authentifié');
  final rows=await client.from('conversation_members').select('conversation_id,conversations(id,title,created_at)').eq('user_id',u.id);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
 Future<List<Map<String,dynamic>>> messages(String conversationId) async {
  final rows=await client.from('messages').select().eq('conversation_id',conversationId).order('created_at');
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
}