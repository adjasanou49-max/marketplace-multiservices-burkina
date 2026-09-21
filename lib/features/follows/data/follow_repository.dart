import 'package:supabase_flutter/supabase_flutter.dart';

class FollowRepository {
  const FollowRepository(this.client);

  final SupabaseClient client;

  Future<bool> toggleProduct(String productId) async {
    final result = await client.rpc(
      'toggle_product_favorite',
      params: {'p_product_id': productId},
    );
    return result as bool;
  }

  Future<bool> toggleShop(String shopId) async {
    final result = await client.rpc(
      'toggle_shop_follow',
      params: {'p_shop_id': shopId},
    );
    return result as bool;
  }

  Future<List<Map<String, dynamic>>> favoriteProducts() async {
    final rows = await client.rpc(
      'my_favorite_products',
      params: {'p_limit': 100},
    );
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> followedShops() async {
    final rows = await client.rpc(
      'my_followed_shops',
      params: {'p_limit': 100},
    );
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}