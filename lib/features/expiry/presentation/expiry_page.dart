import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../products/presentation/product_grid.dart';
import '../data/expiry_repository.dart';

final expiryRepositoryProvider = Provider<ExpiryRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : ExpiryRepository(client);
});

final expiringProductsProvider =
    FutureProvider<List<ExpiryProduct>>((ref) async {
  final repository = ref.watch(expiryRepositoryProvider);
  if (repository == null) return const [];
  final products = await repository.fetchExpiringSoon();
  return products
      .map(
        (product) => ExpiryProduct(
          productId: product.id,
          name: product.name,
          product: product,
        ),
      )
      .toList();
});

class ExpiryProduct {
  const ExpiryProduct({
    required this.productId,
    required this.name,
    required this.product,
  });

  final String productId;
  final String name;
  final dynamic product;
}

class ExpiryPage extends ConsumerWidget {
  const ExpiryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expiringProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expiration proche')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (items) {
          final products = items.map((item) => item.product as dynamic).toList();
          if (products.isEmpty) {
            return const Center(
              child: Text('Aucun produit proche de sa date d’expiration.'),
            );
          }
          return ProductGrid(
            products: products.cast(),
          );
        },
      ),
    );
  }
}
