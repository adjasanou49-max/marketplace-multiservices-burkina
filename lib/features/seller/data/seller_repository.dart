import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/seller_dashboard.dart';

class SellerRepository {
  const SellerRepository(this.client);
  final SupabaseClient client;

  Future<SellerDashboard> dashboard() async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');
    final seller = await client.from('sellers').select('id').eq('user_id', user.id).maybeSingle();
    if (seller == null) return const SellerDashboard(shopCount: 0, productCount: 0, pendingOrders: 0, revenue: 0);
    final sellerId = seller['id'] as String;
    final shops = await client.from('shops').select('id').eq('seller_id', sellerId);
    final shopIds = (shops as List).map((e) => e['id'] as String).toList();
    var productCount = 0;
    if (shopIds.isNotEmpty) {
      final products = await client.from('products').select('id').inFilter('shop_id', shopIds);
      productCount = (products as List).length;
    }
    return SellerDashboard(shopCount: shopIds.length, productCount: productCount, pendingOrders: 0, revenue: 0);
  }
}