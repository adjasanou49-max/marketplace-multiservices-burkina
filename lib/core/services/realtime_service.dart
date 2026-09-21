import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeChannel? subscribeTable({
    required String key,
    required String table,
    required void Function(Map<String, dynamic>) onChange,
    String? column,
    String? value,
  }) {
    try {
      final client = Supabase.instance.client;
      final channel = client.channel(key);

      void handleChange(PostgresChangePayload payload) {
        onChange(
          Map<String, dynamic>.from(
            payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord,
          ),
        );
      }

      final configured = column != null && value != null
          ? channel.onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: column,
                value: value,
              ),
              callback: handleChange,
            )
          : channel.onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              callback: handleChange,
            );

      configured.subscribe();
      _channels[key] = configured;
      return configured;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    if (_channels.isEmpty) return;
    final client = Supabase.instance.client;
    for (final channel in _channels.values) {
      await client.removeChannel(channel);
    }
    _channels.clear();
  }
}
