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
          'id,shop_id,cuisine_types,preparation_time_min,delivery_available',
        )
        .eq('delivery_available', true)
        .limit(limit);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
