import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantRepository {
  const RestaurantRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> restaurants() async {
    final rows = await client
        .from('restaurant_profiles')
        .select(
          'id,shop_id,cuisine_types,preparation_time_min,delivery_available,shops(name,address,status),restaurant_menus(id,name,description,restaurant_menu_items(id,name,description,price,active,sort_order))',
        )
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
