import 'package:supabase_flutter/supabase_flutter.dart';

class MessageSenderRepository {
  const MessageSenderRepository(this.client);

  final SupabaseClient client;

  Future<void> send({
    required String conversationId,
    required String body,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final text = body.trim();
    if (text.isEmpty) return;

    final membership = await client
        .from('conversation_members')
        .select('conversation_id')
        .eq('conversation_id', conversationId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (membership == null) {
      throw StateError('Conversation inaccessible');
    }

    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'body': text,
    });
  }
}
