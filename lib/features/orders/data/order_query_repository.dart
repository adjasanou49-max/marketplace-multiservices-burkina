import 'package:supabase_flutter/supabase_flutter.dart';

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String status;
  final num total;
  final String currency;
  final DateTime createdAt;
}

class OrderQueryRepository {
  const OrderQueryRepository(this.client);

  final SupabaseClient client;

  Future<List<OrderSummary>> mine({
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await client.rpc(
      'get_my_orders',
      params: {'p_limit': limit, 'p_offset': offset},
    );

    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return OrderSummary(
        id: row['order_id'] as String,
        status: row['status'].toString(),
        total: row['total'] as num,
        currency: row['currency'] as String? ?? 'XOF',
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> detail(String orderId) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');

    final order = await client
        .from('orders')
        .select()
        .eq('id', orderId)
        .eq('customer_id', user.id)
        .single();

    final groups = await client
        .from('order_groups')
        .select('id,shop_id,status,subtotal,created_at,shops(name)')
        .eq('order_id', orderId)
        .order('created_at');

    final groupIds = (groups as List)
        .map((row) => row['id'])
        .whereType<String>()
        .toList();

    final items = groupIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await client
                .from('order_items')
                .select()
                .inFilter('order_group_id', groupIds) as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();

    return {
      'order': Map<String, dynamic>.from(order),
      'groups': (groups as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      'items': items,
    };
  }

  Future<void> cancelUnpaid(String orderId) async {
    await client.rpc(
      'cancel_unpaid_order',
      params: {'p_order_id': orderId},
    );
  }
}
