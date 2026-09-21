import 'package:supabase_flutter/supabase_flutter.dart';

class MessageSenderRepository {
 const MessageSenderRepository(this.client); final SupabaseClient client;
 Future<void> send({required String conversationId,required String body}) async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final text=body.trim();if(text.isEmpty)return;
  await client.from('messages').insert({'conversation_id':conversationId,'sender_id':u.id,'body':text});
 }
}