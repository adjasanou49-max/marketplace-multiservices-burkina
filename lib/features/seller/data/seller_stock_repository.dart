import 'package:supabase_flutter/supabase_flutter.dart';

class SellerStockRepository {
  const SellerStockRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> stock({String? shopId}) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final seller = await client
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (seller == null) {
      throw StateError('Profil vendeur introuvable');
    }

    final shops = await client
        .from('shops')
        .select('id')
        .eq('seller_id', seller['id']);

    final ownedShopIds = (shops as List)
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (ownedShopIds.isEmpty) return const [];

    final targetShopIds = shopId == null || shopId.trim().isEmpty
        ? ownedShopIds
        : <String>[shopId.trim()];

    if (shopId != null && !ownedShopIds.contains(shopId.trim())) {
      throw StateError('Boutique inaccessible');
    }

    final rows = await client
        .from('inventory')
        .select(
          'product_id,quantity,reserved_quantity,updated_at,'
          'products!inner(name,shop_id)',
        )
        .inFilter('products.shop_id', targetShopIds)
        .order('updated_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
