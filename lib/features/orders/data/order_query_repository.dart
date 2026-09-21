import 'package:supabase_flutter/supabase_flutter.dart';

class OrderSummary {
  const OrderSummary({required this.id, required this.status, required this.total, required this.currency, required this.createdAt});
  final String id;
  final String status;
  final num total;
  final String currency;
  final DateTime createdAt;
}

class OrderQueryRepository {
  const OrderQueryRepository(this.client);
  final SupabaseClient client;

  Future<List<OrderSummary>> mine({int limit = 30, int offset = 0}) async {
    final rows = await client.rpc('get_my_orders', params: {'p_limit': limit, 'p_offset': offset});
    return (rows as List).map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      return OrderSummary(
        id: m['order_id'] as String,
        status: m['status'].toString(),
        total: m['total'] as num,
        currency: m['currency'] as String? ?? 'XOF',
        createdAt: DateTime.parse(m['created_at'] as String),
      );
    }).toList();
  }
}
