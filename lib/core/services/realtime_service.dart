import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  RealtimeChannel? _channel;

  RealtimeChannel? subscribe(
    String name, {
    required void Function(Map<String, dynamic>) onChange,
  }) {
    try {
      final client = Supabase.instance.client;
      _channel = client.channel(name)
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) => onChange(payload.newRecord),
        )
        ..subscribe();
      return _channel;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    final channel = _channel;
    if (channel != null) {
      await Supabase.instance.client.removeChannel(channel);
      _channel = null;
    }
  }
}
