import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/marketplace_module.dart';

class ModuleRepository {
  const ModuleRepository(this.client);

  final SupabaseClient client;

  Future<List<MarketplaceModule>> enabledModules() async {
    final rows = await client
        .from('marketplace_modules')
        .select('key,label,route,icon_name,config')
        .eq('enabled', true)
        .order('sort_order');

    return (rows as List)
        .map(
          (row) =>
              MarketplaceModule.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }
}
