import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/messaging_repository.dart';
import 'conversation_page.dart';

final messagingRepositoryProvider = Provider<MessagingRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : MessagingRepository(client);
});

final conversationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(messagingRepositoryProvider);
  if (repo == null) return const [];
  return repo.conversations();
});

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucune conversation'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) {
              final row = items[index];
              final value = row['conversations'];
              final conversation = value is Map
                  ? Map<String, dynamic>.from(value)
                  : <String, dynamic>{};
              final conversationId = conversation['id']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(conversation['title'] as String? ?? 'Conversation'),
                subtitle: Text(conversation['created_at'] as String? ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: conversationId.isEmpty
                    ? null
                    : () => GoRouter.of(context).push(
                          '/conversation/$conversationId',
                        ),
              );
            },
          );
        },
      ),
    );
  }
}
