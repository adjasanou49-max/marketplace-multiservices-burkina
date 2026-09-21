import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
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
      appBar: AppBar(title: const Text('Restaurants')),
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
                final rows = snapshot.data ?? const [];
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('Aucun restaurant disponible actuellement.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final row = rows[index];
                    final cuisines = row['cuisine_types'];
                    final cuisineText = cuisines is List
                        ? cuisines.join(', ')
                        : cuisines?.toString() ?? 'Cuisine non précisée';
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.restaurant_outlined),
                      ),
                      title: Text(
                        'Restaurant #${row['shop_id']?.toString().substring(0, 8) ?? '—'}',
                      ),
                      subtitle: Text(
                        '$cuisineText • Préparation ${row['preparation_time_min'] ?? '—'} min',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                );
              },
            ),
    );
  }
}
