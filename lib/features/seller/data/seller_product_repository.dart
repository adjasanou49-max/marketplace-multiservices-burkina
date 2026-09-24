import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProductRepository {
  const SellerProductRepository(this.client);
  final SupabaseClient client;

  Future<String> _mySellerId() async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');
    final row = await client.from('sellers').select('id').eq('user_id', user.id).single();
    return row['id'] as String;
  }

  Future<void> _assertShopOwnership(String shopId) async {
    final sellerId = await _mySellerId();
    final shop = await client.from('shops').select('id').eq('id', shopId).eq('seller_id', sellerId).maybeSingle();
    if (shop == null) throw StateError('Boutique inaccessible');
  }

  Future<List<Map<String, dynamic>>> products(String shopId) async {
    await _assertShopOwnership(shopId);
    final rows = await client
        .from('products')
        .select('id,name,price,status,shop_id,inventory(quantity,reserved_quantity)')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> updateActive(String productId, bool active) async {
    if (active) {
      throw StateError(
        'L’activation d’un produit nécessite une approbation administrateur.',
      );
    }

    final sellerId = await _mySellerId();
    final product = await client
        .from('products')
        .select('id,shop_id')
        .eq('id', productId)
        .maybeSingle();
    if (product == null) throw StateError('Produit introuvable');
    final shop = await client
        .from('shops')
        .select('id')
        .eq('id', product['shop_id'])
        .eq('seller_id', sellerId)
        .maybeSingle();
    if (shop == null) throw StateError('Produit inaccessible');
    await client
        .from('products')
        .update({'status': active ? 'ACTIVE' : 'INACTIVE'})
        .eq('id', productId);
  }
}
