import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/application/category_controller.dart';
import '../../categories/presentation/category_strip.dart';
import '../../products/application/product_controller.dart';
import '../../products/presentation/product_grid.dart';
import '../../shops/application/shop_controller.dart';
import '../../shops/presentation/shop_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(productsProvider);
    final shops = ref.watch(shopsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Burkina'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(shopsProvider);
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit, une boutique...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
                ),
              ),
            ),
            categories.when(
              loading: () => const SizedBox(height: 104, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Erreur catégories : $e')),
              data: (items) => CategoryStrip(categories: items),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text('Produits populaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            products.when(
              loading: () => const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Erreur produits : $e')),
              data: (items) => ProductGrid(products: items),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 18, 12, 4),
              child: Text('Boutiques', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            shops.when(
              loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Erreur boutiques : $e')),
              data: (items) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: items.map((shop) => ShopCard(shop: shop)).toList()),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Suivis'),
          NavigationDestination(icon: Icon(Icons.local_offer_outlined), label: 'Promos'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
