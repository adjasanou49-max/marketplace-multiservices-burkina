import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/message_sender_repository.dart';
import '../data/messaging_repository.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final controller = TextEditingController();

  RealtimeChannel? _channel;
  List<Map<String, dynamic>> messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    final rows =
        await MessagingRepository(client).messages(widget.conversationId);
    if (!mounted) return;

    _mergeMessages(rows);
  }

  void _subscribe() {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    final channel = client.channel('conversation:${widget.conversationId}');
    _channel = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            if (!mounted) return;
            _mergeMessages([
              Map<String, dynamic>.from(payload.newRecord),
            ]);
          },
        )
        .subscribe();
  }

  void _mergeMessages(List<Map<String, dynamic>> incoming) {
    final byKey = <String, Map<String, dynamic>>{};

    for (final message in messages) {
      byKey[_messageKey(message)] = message;
    }
    for (final message in incoming) {
      byKey[_messageKey(message)] = message;
    }

    final merged = byKey.values.toList()
      ..sort((left, right) {
        final leftTime =
            DateTime.tryParse(left['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final rightTime =
            DateTime.tryParse(right['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        return leftTime.compareTo(rightTime);
      });

    setState(() => messages = merged);
  }

  String _messageKey(Map<String, dynamic> message) {
    final id = message['id']?.toString();
    if (id != null && id.isNotEmpty) return 'id:$id';

    return [
      message['conversation_id']?.toString() ?? widget.conversationId,
      message['sender_id']?.toString() ?? '',
      message['created_at']?.toString() ?? '',
      message['body']?.toString() ?? '',
    ].join('|');
  }

  Future<void> _sendMessage() async {
    final client = ref.read(supabaseProvider);
    final text = controller.text.trim();
    if (client == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await MessageSenderRepository(client).send(
        conversationId: widget.conversationId,
        body: text,
      );
      if (!mounted) return;
      controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Envoi impossible : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, index) => ListTile(
                title: Text(messages[index]['body'] as String? ?? ''),
                subtitle:
                    Text(messages[index]['created_at']?.toString() ?? ''),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message',
                    ),
                  ),
                ),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _sending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
