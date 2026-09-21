import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : NotificationRepository(client);
});

final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  if (repo == null) return const [];
  return repo.mine();
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final repository = ref.watch(notificationRepositoryProvider);

    Future<void> markAll() async {
      if (repository == null) return;
      try {
        await repository.markAllRead();
        ref.invalidate(notificationsProvider);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $error')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Tout marquer comme lu',
            onPressed: repository == null ? null : markAll,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucune notification'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, index) {
                final item = items[index];
                final unread = item['read_at'] == null;
                return Card(
                  elevation: unread ? 2 : 0,
                  child: ListTile(
                    leading: Icon(
                      unread
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_outlined,
                    ),
                    title: Text(
                      item['title']?.toString() ?? 'Notification',
                      style: TextStyle(
                        fontWeight:
                            unread ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    subtitle: Text(item['body']?.toString() ?? ''),
                    trailing: unread
                        ? const Icon(Icons.fiber_manual_record, size: 12)
                        : null,
                    onTap: repository == null
                        ? null
                        : () async {
                            try {
                              await repository.markRead(
                                item['id'].toString(),
                              );
                              ref.invalidate(notificationsProvider);
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $error')),
                              );
                            }
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
