import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/repository_providers.dart';

class RestaurantDetailPage extends ConsumerWidget {
  const RestaurantDetailPage({super.key, required this.restaurantId});

  final String restaurantId;

  Future<Map<String, dynamic>> _load(SupabaseClient client) async {
    final profile = await client
        .from('restaurant_profiles')
        .select(
          'id,shop_id,cuisine_types,preparation_time_min,delivery_available,
          shops(name,logo_url,cover_url,description,phone,address,status,verification_status)'
        )
        .eq('id', restaurantId)
        .single();

    final menus = await client
        .from('restaurant_menus')
        .select('id,name,description,active,sort_order')
        .eq('restaurant_id', restaurantId)
        .eq('active', true)
        .order('sort_order');

    final menuIds = (menus as List)
        .map((row) => row['id'])
        .whereType<String>()
        .toList();

    final items = menuIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : (await client
                .from('restaurant_menu_items')
                .select('id,menu_id,product_id,name,description,price,active,sort_order')
                .inFilter('menu_id', menuIds)
                .eq('active', true)
                .order('sort_order') as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();

    return {
      'profile': Map<String, dynamic>.from(profile),
      'menus': (menus as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      'items': items,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(client),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Restaurant introuvable.'));
          }

          final profile = Map<String, dynamic>.from(data['profile'] as Map);
          final shop = profile['shops'] is Map
              ? Map<String, dynamic>.from(profile['shops'])
              : const <String, dynamic>{};
          final menus = (data['menus'] as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final items = (data['items'] as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              if (shop['cover_url']?.toString().isNotEmpty == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Image.network(
                      shop['cover_url'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: shop['logo_url']?.toString().isNotEmpty == true
                      ? NetworkImage(shop['logo_url'].toString())
                      : null,
                  child: shop['logo_url']?.toString().isNotEmpty == true
                      ? null
                      : const Icon(Icons.restaurant_outlined),
                ),
                title: Text(
                  shop['name']?.toString() ?? 'Restaurant',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                subtitle: Text(
                  '${(profile['cuisine_types'] as List?)?.join(', ') ?? 'Cuisine non précisée'} • '
                  '${profile['preparation_time_min'] ?? '—'} min',
                ),
              ),
              if (shop['description']?.toString().trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(shop['description'].toString()),
                ),
              if (profile['delivery_available'] == true)
                const Chip(
                  avatar: Icon(Icons.delivery_dining_outlined, size: 18),
                  label: Text('Livraison disponible'),
                ),
              const SizedBox(height: 12),
              if (menus.isEmpty)
                const Text('Aucun menu disponible actuellement.'),
              for (final menu in menus) ...[
                Text(
                  menu['name']?.toString() ?? 'Menu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (menu['description']?.toString().trim().isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: Text(menu['description'].toString()),
                  ),
                for (final item in items.where((row) => row['menu_id'] == menu['id']))
                  Card(
                    child: ListTile(
                      title: Text(item['name']?.toString() ?? 'Article'),
                      subtitle: Text(item['description']?.toString() ?? ''),
                      trailing: Text(
                        '${item['price'] ?? 0} XOF',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}