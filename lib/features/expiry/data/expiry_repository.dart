import 'package:supabase_flutter/supabase_flutter.dart';

import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';

class ExpiryRepository {
  const ExpiryRepository(this.client);

  final SupabaseClient client;

  Future<List<Product>> fetchExpiringSoon({
    int minDays = 5,
    int maxDays = 30,
    int limit = 40,
  }) async {
    if (minDays < 0 || maxDays < minDays) {
      throw ArgumentError('Période d’expiration invalide.');
    }

    final from = DateTime.now().toUtc().add(Duration(days: minDays));
    final to = DateTime.now().toUtc().add(Duration(days: maxDays));

    final rows = await client
        .from('products')
        .select(
          'id,name,slug,description,price,status,category_id,shop_id,'
          'expiry_date,product_images(storage_path,sort_order)',
        )
        .eq('status', 'ACTIVE')
        .eq('is_expirable', true)
        .gte('expiry_date', from.toIso8601String().substring(0, 10))
        .lte('expiry_date', to.toIso8601String().substring(0, 10))
        .order('expiry_date')
        .limit(limit);

    return ProductRepository(client).hydrateRows(rows as List);
  }
}
