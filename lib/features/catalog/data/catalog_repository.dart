import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogRepository {
  const CatalogRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> categoryTypes() async {
    final rows = await client
        .from('category_types')
        .select('id,name,slug,is_active,sort_order')
        .eq('is_active', true)
        .order('sort_order')
        .limit(50);

    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final rows = await client
        .from('categories')
        .select(
          'id,category_type_id,parent_id,name,slug,icon_url,image_url,is_active,sort_order',
        )
        .eq('is_active', true)
        .order('sort_order')
        .limit(200);

    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> products({
    String? categoryId,
    int offset = 0,
    int limit = 24,
  }) async {
    if (offset < 0 || limit <= 0 || limit > 100) {
      throw ArgumentError('Pagination invalide.');
    }

    final end = offset + limit - 1;

    var query = client
        .from('products')
        .select(
          'id,shop_id,category_id,name,slug,description,price,compare_at_price,'
          'status,is_expirable,expiry_date,created_at,'
          'shops(name,status),product_images(storage_path,sort_order,alt_text)',
        )
        .eq('status', 'ACTIVE');

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(offset, end);

    return _maps(rows);
  }

  List<Map<String, dynamic>> _maps(dynamic rows) {
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
