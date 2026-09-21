import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : RestaurantRepository(client);
});

class RestaurantsPage extends ConsumerStatefulWidget {
  const RestaurantsPage({super.key});

  @override
  ConsumerState<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends ConsumerState<RestaurantsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(restaurantRepositoryProvider)?.restaurants() ??
        Future.value(const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur : ' + snapshot.error.toString()),
            );
          }

          final restaurants =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (restaurants.isEmpty) {
            return const Center(child: Text('Aucun restaurant disponible.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final restaurant = restaurants[index];
              final shop = restaurant['shops'] is Map
                  ? Map<String, dynamic>.from(restaurant['shops'] as Map)
                  : const <String, dynamic>{};
              final cuisines = restaurant['cuisine_types'];

              final rawMenus = restaurant['restaurant_menus'];
              final menus = rawMenus is List
                  ? rawMenus
                      .whereType<Map>()
                      .map((row) => Map<String, dynamic>.from(row))
                      .toList()
                  : const <Map<String, dynamic>>[];

              return Card(
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.restaurant_outlined),
                  ),
                  title: Text(
                    shop['name']?.toString() ?? 'Restaurant',
                  ),
                  subtitle: Text(
                    cuisines is List && cuisines.isNotEmpty
                        ? cuisines.join(', ')
                        : 'Cuisine non renseignée',
                  ),
                  children: [
                    for (final menu in menus) _MenuSection(menu: menu),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.menu});

  final Map<String, dynamic> menu;

  @override
  Widget build(BuildContext context) {
    final rawItems = menu['restaurant_menu_items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList()
        : const <Map<String, dynamic>>[];

    return ExpansionTile(
      title: Text(menu['name']?.toString() ?? 'Menu'),
      subtitle: Text(menu['description']?.toString() ?? ''),
      children: [
        for (final item in items)
          ListTile(
            title: Text(item['name']?.toString() ?? 'Plat'),
            subtitle: Text(item['description']?.toString() ?? ''),
            trailing: Text((item['price']?.toString() ?? '0') + ' XOF'),
          ),
      ],
    );
  }
}
