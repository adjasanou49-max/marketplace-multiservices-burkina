import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends ConsumerState<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  RealtimeChannel? _notificationsChannel;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _startRealtime();
  }

  void _startRealtime() {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    _notificationsChannel = client
        .channel('notifications-' + user.id)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) {
            if (!mounted) return;
            setState(() => _future = _load());
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final client = ref.read(supabaseProvider);
    final channel = _notificationsChannel;
    if (client != null && channel != null) {
      client.removeChannel(channel);
    }
    super.dispose();
  }


  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;

    if (client == null || user == null) return const [];

    final rows = await client
        .from('notifications')
        .select('id,type,title,body,data,read_at,created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> _markRead(String id) async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;

    if (client == null || user == null) return;

    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', user.id);

    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(supabaseProvider)?.auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Connectez-vous pour voir vos notifications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (items.isEmpty) {
            return const Center(
              child: Text('Aucune notification.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = items[index];
              final unread = item['read_at'] == null;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      unread
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                    ),
                  ),
                  title: Text(
                    item['title']?.toString() ?? 'Notification',
                    style: TextStyle(
                      fontWeight:
                          unread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(
                    (item['body']?.toString() ?? '') +
                        '\n' +
                        (item['created_at']?.toString() ?? ''),
                  ),
                  onTap: unread
                      ? () => _markRead(item['id'].toString())
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
