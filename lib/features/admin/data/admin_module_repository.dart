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
    await client.rpc(
      'admin_set_marketplace_module_enabled',
      params: {
        'p_key': key,
        'p_enabled': enabled,
      },
    );
  }
}