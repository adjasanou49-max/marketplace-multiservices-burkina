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

    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return hydrateRows(rows);
  }

  Future<Product?> fetchActiveById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;

    final row = await client
        .from('products')
        .select(
          'id,name,slug,description,price,status,category_id,shop_id,'
          'product_images(storage_path,sort_order)',
        )
        .eq('id', normalizedId)
        .eq('status', 'ACTIVE')
        .maybeSingle();

    if (row == null) return null;

    final products = await hydrateRows([row]);
    return products.isEmpty ? null : products.first;
  }

  Future<List<Product>> fetchActivePage({
    String? categoryId,
    int limit = 24,
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    if (limit <= 0 ||
        (beforeCreatedAt == null) != (beforeId == null) ||
        (beforeId != null && beforeId.trim().isEmpty)) {
      throw ArgumentError('Pagination produit invalide.');
    }

    var query = client
        .from('products')
        .select(
          'id,name,slug,description,price,status,category_id,shop_id,'
          'created_at,product_images(storage_path,sort_order)',
        )
        .eq('status', 'ACTIVE');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (beforeCreatedAt != null && beforeId != null) {
      final cursor = beforeCreatedAt.toUtc().toIso8601String();
      query = query.or(
        'created_at.lt.$cursor,and(created_at.eq.$cursor,id.lt.$beforeId)',
      );
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return hydrateRows(rows);
  }

  Future<List<Product>> hydrateRows(Iterable<dynamic> rows) async {
    final input = rows.toList(growable: false);
    final signedUrlCache = <String, Future<String>>{};

    Future<String?> signedUrlFor(String path) {
      final existing = signedUrlCache[path];
      if (existing != null) {
        return existing.then<String?>((value) => value);
      }

      final future = client.storage
          .from('product-media')
          .createSignedUrl(path, 3600);
      signedUrlCache[path] = future;
      return future.then<String?>((value) => value);
    }

    Future<Product> hydrate(dynamic raw) async {
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
            imageUrl = await signedUrlFor(path);
          } catch (_) {
            imageUrl = null;
          }
        }
      }

      row['image_url'] = imageUrl;
      row['currency'] = 'XOF';
      return Product.fromMap(row);
    }

    return Future.wait(input.map(hydrate));
  }
}
