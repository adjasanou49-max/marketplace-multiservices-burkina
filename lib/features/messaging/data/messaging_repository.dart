import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingRepository {
  const MessagingRepository(this.client);

  final SupabaseClient client;

  Future<String> createSupportConversation() async {
    final raw = await client.rpc('create_support_conversation');
    return raw.toString();
  }

  Future<List<Map<String, dynamic>>> conversations() async {
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final members = await client
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', user.id);

    final ids = (members as List)
        .map((row) => (row as Map)['conversation_id']?.toString())
        .whereType<String>()
        .toList();

    if (ids.isEmpty) return const [];

    final rows = await client
        .from('conversations')
        .select('id,order_id,type,created_at')
        .inFilter('id', ids)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> messages(
    String conversationId,
  ) async {
    final rows = await client
        .from('messages')
        .select('id,conversation_id,sender_id,body,status,created_at')
        .eq('conversation_id', conversationId)
        .order('created_at')
        .limit(200);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> send(
    String conversationId,
    String body,
  ) async {
    final text = body.trim();

    if (text.isEmpty || text.length > 5000) {
      throw ArgumentError('Message invalide.');
    }

    final user = client.auth.currentUser;
    if (user == null) throw StateError('Non authentifié.');

    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'body': text,
      'status': 'SENT',
    });
  }

  Future<void> markRead(String conversationId) async {
    await client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }
}
