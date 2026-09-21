import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/product.dart';

class ProductRepository {
  const ProductRepository(this.client);

  final SupabaseClient client;

  Future<List<Product>> fetchActive({
    String? categoryId,
    int limit = 30,
  }) async {
    var query = client
        .from('products')
        .select(
          'id,name,slug,description,price,status,category_id,shop_id,'
          'product_images(storage_path,sort_order)',
        )
        .eq('status', 'ACTIVE');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final rows = await query.order('created_at', ascending: false).limit(limit);
    return hydrateRows(rows);
  }

  Future<List<Product>> hydrateRows(Iterable<dynamic> rows) async {
    final products = <Product>[];

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final rawImages = row.remove('product_images');
      String? imageUrl;

      if (rawImages is List && rawImages.isNotEmpty) {
        final images = rawImages
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
          ..sort(
            (left, right) => (left['sort_order'] as num? ?? 0)
                .compareTo(right['sort_order'] as num? ?? 0),
          );

        final path = images.first['storage_path'] as String?;
        if (path != null && path.isNotEmpty) {
          try {
            imageUrl = await client.storage
                .from('product-media')
                .createSignedUrl(path, 3600);
          } catch (_) {
            imageUrl = null;
          }
        }
      }

      row['image_url'] = imageUrl;
      row['currency'] = 'XOF';
      products.add(Product.fromMap(row));
    }

    return products;
  }
}
