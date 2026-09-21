import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/seller_dashboard.dart';

class SellerRepository {
  const SellerRepository(this.client);

  final SupabaseClient client;

  Future<SellerDashboard> dashboard() async {
    if (client.auth.currentUser == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final rows = await client.rpc('get_seller_dashboard');
    final items = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    var activeProducts = 0;
    var pendingOrders = 0;
    var revenue = 0.0;
    for (final row in items) {
      activeProducts += (row['active_products'] as num?)?.toInt() ?? 0;
      pendingOrders += (row['pending_orders'] as num?)?.toInt() ?? 0;
      revenue += (row['gross_sales'] as num?)?.toDouble() ?? 0;
    }

    return SellerDashboard(
      shopCount: items.length,
      productCount: activeProducts,
      pendingOrders: pendingOrders,
      revenue: revenue,
    );
  }
}