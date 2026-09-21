import 'package:supabase_flutter/supabase_flutter.dart';

import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';

class SearchRepository {
  const SearchRepository(this.client);

  final SupabaseClient client;

  Future<List<Product>> search(String query, {int limit = 40}) async {
    final term = query.trim();
    if (term.isEmpty) return const [];

    final rows = await client
        .from('products')
        .select(
          'id,name,slug,description,price,status,category_id,shop_id,'
          'product_images(storage_path,sort_order)',
        )
        .eq('status', 'ACTIVE')
        .ilike('name', '%$term%')
        .order('created_at', ascending: false)
        .limit(limit);

    return ProductRepository(client).hydrateRows(rows as List);
  }
}
