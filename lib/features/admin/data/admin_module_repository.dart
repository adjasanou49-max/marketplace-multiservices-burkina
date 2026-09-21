import 'package:supabase_flutter/supabase_flutter.dart';

class AdminModuleRepository {
  const AdminModuleRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> all() async {
    final rows = await client
        .from('marketplace_modules')
        .select('key,label,route,icon_name,enabled,sort_order,config,updated_at')
        .order('sort_order');
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> setEnabled(String key, bool enabled) async {
    await client
        .from('marketplace_modules')
        .update({
          'enabled': enabled,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('key', key);
  }
}