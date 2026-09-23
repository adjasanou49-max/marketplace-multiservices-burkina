import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingRepository {
  const MessagingRepository(this.client);

  final SupabaseClient client;

  Future<String> _currentUserId() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }
    return user.id;
  }

  Future<void> _assertMember(String conversationId) async {
    final userId = await _currentUserId();
    final membership = await client
        .from('conversation_members')
        .select('conversation_id')
        .eq('conversation_id', conversationId)
        .eq('user_id', userId)
        .maybeSingle();

    if (membership == null) {
      throw StateError('Conversation inaccessible');
    }
  }

  Future<List<Map<String, dynamic>>> conversations() async {
    final userId = await _currentUserId();
    final rows = await client
        .from('conversation_members')
        .select('conversation_id,conversations(id,title,created_at)')
        .eq('user_id', userId);
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    await _assertMember(conversationId);
    final rows = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
