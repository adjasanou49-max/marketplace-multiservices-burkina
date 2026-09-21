import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_grid.dart';
import '../data/expiry_repository.dart';

final expiryRepositoryProvider = Provider<ExpiryRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : ExpiryRepository(client);
});

final expiringProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(expiryRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchExpiringSoon();
});

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
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('Aucun produit proche de sa date d’expiration.'),
            );
          }
          return ProductGrid(products: products);
        },
      ),
    );
  }
}
