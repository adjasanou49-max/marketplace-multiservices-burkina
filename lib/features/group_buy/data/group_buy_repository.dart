import 'package:supabase_flutter/supabase_flutter.dart';

class GroupBuyRepository {
  const GroupBuyRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> active() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await client
        .from('group_buys')
        .select('id,product_id,seller_id,title,target_quantity,current_quantity,group_price,starts_at,ends_at,status')
        .eq('status', 'OPEN')
        .lte('starts_at', now)
        .gt('ends_at', now)
        .order('ends_at')
        .limit(100);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<String> join({required String groupBuyId, int quantity = 1}) async {
    final result = await client.rpc(
      'join_group_buy',
      params: {
        'p_group_buy_id': groupBuyId,
        'p_quantity': quantity,
      },
    );
    return result as String;
  }
}