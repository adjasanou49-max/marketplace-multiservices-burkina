import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeChannel? subscribeTable({
    required String key,
    required String table,
    required void Function(Map<String,dynamic>) onChange,
    String? filter,
  }) {
    try {
      final client=Supabase.instance.client;
      final channel=client.channel(key);
      final config=filter==null
        ? channel.onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:table,callback:(p)=>onChange(p.newRecord))
        : channel.onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:table,filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:filter.split('=').first,value:filter.split('=').last),callback:(p)=>onChange(p.newRecord));
      config.subscribe();
      _channels[key]=config;
      return config;
    } catch (_) { return null; }
  }

  Future<void> dispose() async {
    for(final c in _channels.values) { await Supabase.instance.client.removeChannel(c); }
    _channels.clear();
  }
}