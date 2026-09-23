import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/shop.dart';

class ShopRepository {
  const ShopRepository(this.client);

  final SupabaseClient client;

  Future<Shop?> fetchActiveById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;

    final row = await client
        .from('shops')
        .select()
        .eq('id', normalizedId)
        .eq('status', 'ACTIVE')
        .maybeSingle();

    return row == null
        ? null
        : Shop.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<Shop>> fetchActive({int limit = 20}) async {
    final rows = await client
        .from('shops')
        .select()
        .eq('status', 'ACTIVE')
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => Shop.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
