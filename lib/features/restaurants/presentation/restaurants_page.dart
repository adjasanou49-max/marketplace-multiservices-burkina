import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/domain/cart_item.dart';
import '../data/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : RestaurantRepository(client);
});

class RestaurantsPage extends ConsumerWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(restaurantRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(restaurantRepositoryProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: repository == null
          ? const Center(child: Text('Supabase non configuré'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.activeRestaurants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                if (rows.isEmpty) {
                  return const Center(child: Text('Aucun restaurant disponible actuellement.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final row = rows[index];
                    final rawShop = row['shops'];
                    final shop = rawShop is Map
                        ? Map<String, dynamic>.from(rawShop)
                        : const <String, dynamic>{};
                    final cuisines = row['cuisine_types'];
                    final cuisineText = cuisines is List
                        ? cuisines.join(', ')
                        : cuisines?.toString() ?? 'Cuisine non précisée';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: shop['logo_url'] != null
                              ? NetworkImage(shop['logo_url'].toString())
                              : null,
                          child: shop['logo_url'] == null
                              ? const Icon(Icons.restaurant_outlined)
                              : null,
                        ),
                        title: Text(shop['name']?.toString() ?? 'Restaurant'),
                        subtitle: Text(
                          '$cuisineText • Préparation ${row['preparation_time_min'] ?? '—'} min',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/restaurant/${row['id']}', extra: row),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class RestaurantDetailPage extends ConsumerWidget {
  const RestaurantDetailPage({super.key, required this.restaurant});

  final Map<String, dynamic> restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(restaurantRepositoryProvider);
    final rawShop = restaurant['shops'];
    final shop = rawShop is Map
        ? Map<String, dynamic>.from(rawShop)
        : const <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: Text(shop['name']?.toString() ?? 'Restaurant')),
      body: repository == null
          ? const Center(child: Text('Supabase non configuré'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.menuItems(restaurant['id'].toString()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                final items = snapshot.data ?? const <Map<String, dynamic>>[];
                if (items.isEmpty) {
                  return const Center(child: Text('Le menu est actuellement vide.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final price = (item['price'] as num?) ?? 0;
                    final productId = item['product_id']?.toString();
                    return ListTile(
                      title: Text(item['name']?.toString() ?? 'Plat'),
                      subtitle: Text(
                        '${item['description'] ?? ''}\n${price.toStringAsFixed(0)} XOF',
                      ),
                      isThreeLine: true,
                      trailing: productId == null
                          ? null
                          : IconButton(
                              tooltip: 'Ajouter au panier',
                              icon: const Icon(Icons.add_shopping_cart_outlined),
                              onPressed: () {
                                ref.read(cartControllerProvider.notifier).add(
                                  CartItem(
                                    productId: productId,
                                    quantity: 1,
                                    unitPrice: price,
                                    name: item['name']?.toString() ?? 'Plat',
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Article ajouté au panier.')),
                                );
                              },
                            ),
                    );
                  },
                );
              },
            ),
    );
  }
}