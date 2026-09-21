import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/category.dart';

class CategoryRepository {
  const CategoryRepository(this.client);

  final SupabaseClient client;

  Future<List<Category>> fetchActive() async {
    final rows = await client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((row) => Category.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
