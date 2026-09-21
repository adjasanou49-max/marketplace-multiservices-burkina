import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/messaging_repository.dart';

final messagingRepositoryProvider = Provider<MessagingRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : MessagingRepository(client);
});

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _conversationId;
  RealtimeChannel? _channel;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _future = _loadConversations();
  }

  Future<List<Map<String, dynamic>>> _loadConversations() {
    return ref.read(messagingRepositoryProvider)?.conversations() ??
        Future.value(const []);
  }

  Future<void> _openConversation(String id) async {
    final repo = ref.read(messagingRepositoryProvider);
    if (repo == null) return;

    if (_channel != null) {
      await repo.client.removeChannel(_channel!);
    }

    setState(() => _conversationId = id);

    _channel = repo.client
        .channel('messages-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: id,
          ),
          callback: (_) {
            if (!mounted) return;
            setState(() {});
          },
        )
        .subscribe();

    _poll?.cancel();
    _poll = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (mounted) setState(() {});
      },
    );

    await repo.markRead(id);
  }

  Future<void> _newSupportChat() async {
    final repo = ref.read(messagingRepositoryProvider);
    if (repo == null) return;

    try {
      final id = await repo.createSupportConversation();

      if (!mounted) return;

      setState(() => _future = _loadConversations());
      await _openConversation(id);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de contacter l’administration : ' +
                error.toString(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _poll?.cancel();

    final client = ref.read(supabaseProvider);
    if (_channel != null && client != null) {
      client.removeChannel(_channel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn =
        ref.watch(supabaseProvider)?.auth.currentUser != null;

    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.push('/auth'),
            child: const Text('Se connecter'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _conversationId == null ? 'Messages' : 'Conversation',
        ),
        actions: [
          IconButton(
            onPressed: _newSupportChat,
            tooltip: 'Contacter l’administration',
            icon: const Icon(Icons.support_agent_outlined),
          ),
        ],
      ),
      body: _conversationId == null
          ? _ConversationList(
              future: _future,
              onOpen: _openConversation,
            )
          : _ConversationView(
              conversationId: _conversationId!,
              onBack: () => setState(() => _conversationId = null),
            ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.future,
    required this.onOpen,
  });

  final Future<List<Map<String, dynamic>>> future;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items =
            snapshot.data ?? const <Map<String, dynamic>>[];

        if (items.isEmpty) {
          return const Center(
            child: Text('Aucune conversation.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final item = items[index];

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.chat_outlined),
                ),
                title: Text(
                  item['type']?.toString() ?? 'Conversation',
                ),
                subtitle: Text(
                  item['order_id'] == null
                      ? 'Conversation générale'
                      : 'Commande : ' + item['order_id'].toString(),
                ),
                onTap: () => onOpen(item['id'].toString()),
              ),
            );
          },
        );
      },
    );
  }
}

class _ConversationView extends ConsumerStatefulWidget {
  const _ConversationView({
    required this.conversationId,
    required this.onBack,
  });

  final String conversationId;
  final VoidCallback onBack;

  @override
  ConsumerState<_ConversationView> createState() =>
      _ConversationViewState();
}

class _ConversationViewState
    extends ConsumerState<_ConversationView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref
            .read(messagingRepositoryProvider)
            ?.messages(widget.conversationId) ??
        Future.value(const []);
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    final repo = ref.read(messagingRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.send(widget.conversationId, body);
      _controller.clear();

      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Envoi impossible : ' + error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(supabaseProvider)?.auth.currentUser?.id;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Conversations'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final messages =
                  snapshot.data ?? const <Map<String, dynamic>>[];

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: messages.length,
                itemBuilder: (_, index) {
                  final message = messages[index];
                  final mine = message['sender_id'] == userId;

                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 330),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: mine
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      ),
                      child: Text(
                        message['body']?.toString() ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                      hintText: 'Votre message…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
