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
    final today = DateTime.now().toUtc().toIso8601String().split('T').first;

    var query = client
        .from('products')
        .select(
          'id,shop_id,category_id,name,slug,description,price,compare_at_price,'
          'status,is_expirable,expiry_date,created_at,'
          'shops(name,status),product_images(storage_path,sort_order,alt_text)',
        )
        .eq('status', 'ACTIVE')
        .or(
          'is_expirable.eq.false,expiry_date.is.null,expiry_date.gte.' + today,
        );

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(offset, end);

    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> expiringProducts({
    int daysFrom = 5,
    int daysTo = 30,
    int limit = 200,
  }) async {
    if (daysFrom < 0 ||
        daysTo < daysFrom ||
        daysTo > 3650 ||
        limit <= 0 ||
        limit > 500) {
      throw ArgumentError('Filtre d’expiration invalide.');
    }

    final now = DateTime.now();
    final baseDay = DateTime(now.year, now.month, now.day);
    final from =
        baseDay.add(Duration(days: daysFrom)).toIso8601String().split('T').first;
    final to =
        baseDay.add(Duration(days: daysTo)).toIso8601String().split('T').first;

    final rows = await client
        .from('products')
        .select(
          'id,shop_id,category_id,name,slug,description,price,compare_at_price,'
          'status,is_expirable,expiry_date,created_at,shops(name,status),'
          'product_images(storage_path,sort_order,alt_text)',
        )
        .eq('status', 'ACTIVE')
        .eq('is_expirable', true)
        .gte('expiry_date', from)
        .lte('expiry_date', to)
        .order('expiry_date')
        .limit(limit);

    return _maps(rows);
  }

  List<Map<String, dynamic>> _maps(dynamic rows) {
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
