import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/domain/product.dart';

class SearchRepository {
  const SearchRepository(this.client);
  final SupabaseClient client;

  Future<List<Product>> search(String query, {int limit = 40}) async {
    final term = query.trim();
    if (term.isEmpty) return const [];
    final rows = await client.from('products').select().eq('status', 'ACTIVE')
        .ilike('name', '%$term%').order('created_at', ascending: false).limit(limit);
    return (rows as List).map((row) => Product.fromMap(Map<String, dynamic>.from(row as Map))).toList();
  }
}
