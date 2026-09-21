import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionRepository {
  const PromotionRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> active() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await client
        .from('promotions')
        .select('id,seller_id,shop_id,name,promotion_type,value,starts_at,ends_at,active,created_at')
        .eq('active', true)
        .lte('starts_at', now)
        .gt('ends_at', now)
        .order('ends_at')
        .limit(100);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
