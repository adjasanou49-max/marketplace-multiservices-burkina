import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/product.dart';

class ProductRepository {
  const ProductRepository(this.client);

  final SupabaseClient client;

  Future<List<Product>> fetchActive({String? categoryId, int limit = 30}) async {
    var query = client.from('products').select().eq('status', 'ACTIVE');
    if (categoryId != null) query = query.eq('category_id', categoryId);
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((row) => Product.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
