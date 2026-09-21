import 'package:supabase_flutter/supabase_flutter.dart';

class FollowsRepository {
  const FollowsRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> favoriteProducts() async {
    final raw = await client.rpc(
      'my_favorite_products',
      params: {'p_limit': 100},
    );

    return _maps(raw);
  }

  Future<List<Map<String, dynamic>>> followedShops() async {
    final raw = await client.rpc(
      'my_followed_shops',
      params: {'p_limit': 100},
    );

    return _maps(raw);
  }

  Future<void> toggleProductFavorite(String productId) async {
    await client.rpc(
      'toggle_product_favorite',
      params: {'p_product_id': productId},
    );
  }

  Future<void> toggleShopFollow(String shopId) async {
    await client.rpc(
      'toggle_shop_follow',
      params: {'p_shop_id': shopId},
    );
  }

  List<Map<String, dynamic>> _maps(dynamic rows) {
    if (rows is! List) return const [];

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
