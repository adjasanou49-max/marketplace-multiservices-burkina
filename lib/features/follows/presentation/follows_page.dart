import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/follow_controller.dart';

class FollowsPage extends ConsumerWidget {
  const FollowsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(favoriteProductsProvider);
    final shops = ref.watch(followedShopsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes suivis'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(favoriteProductsProvider);
              ref.invalidate(followedShopsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteProductsProvider);
          ref.invalidate(followedShopsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'Produits favoris',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Erreur : $error'),
              data: (items) => items.isEmpty
                  ? const Text('Aucun produit favori.')
                  : Column(
                      children: [
                        for (final item in items)
                          ListTile(
                            leading: const Icon(Icons.favorite),
                            title: Text(item['name']?.toString() ?? 'Produit'),
                            subtitle: Text(
                              '${item['price'] ?? 0} ${item['currency'] ?? 'XOF'}',
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              'Boutiques suivies',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            shops.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Erreur : $error'),
              data: (items) => items.isEmpty
                  ? const Text('Aucune boutique suivie.')
                  : Column(
                      children: [
                        for (final item in items)
                          ListTile(
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(item['name']?.toString() ?? 'Boutique'),
                            subtitle: Text(item['description']?.toString() ?? ''),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}