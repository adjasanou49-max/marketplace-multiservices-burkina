import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/categories/data/category_repository.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/shops/data/shop_repository.dart';

final supabaseProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final categoryRepositoryProvider = Provider<CategoryRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : CategoryRepository(client);
});

final productRepositoryProvider = Provider<ProductRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : ProductRepository(client);
});

final shopRepositoryProvider = Provider<ShopRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : ShopRepository(client);
});
