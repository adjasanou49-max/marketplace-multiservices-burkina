import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantRepository {
  const RestaurantRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> activeRestaurants({
    int limit = 50,
  }) async {
    final rows = await client
        .from('restaurant_profiles')
        .select(
          'id,shop_id,cuisine_types,preparation_time_min,delivery_available,'
          'shops!inner(id,name,description,logo_url,cover_url,status)',
        )
        .eq('delivery_available', true)
        .eq('shops.status', 'ACTIVE')
        .limit(limit);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> menuItems(
    String restaurantId,
  ) async {
    final rows = await client
        .from('restaurant_menu_items')
        .select(
          'id,menu_id,product_id,name,description,price,active,sort_order,'
          'restaurant_menus!inner(id,restaurant_id,name,active)',
        )
        .eq('active', true)
        .eq('restaurant_menus.active', true)
        .eq('restaurant_menus.restaurant_id', restaurantId)
        .order('sort_order');

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
