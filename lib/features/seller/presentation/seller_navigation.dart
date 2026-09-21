import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

import '../data/seller_shop_repository.dart';
import 'seller_dashboard_page.dart';
import 'seller_finance_page.dart';
import 'seller_orders_page.dart';
import 'seller_products_page.dart';

class SellerNavigation extends ConsumerStatefulWidget {
  const SellerNavigation({super.key});

  @override
  ConsumerState<SellerNavigation> createState() => _SellerNavigationState();
}

class _SellerNavigationState extends ConsumerState<SellerNavigation> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: const SellerShopRepository(client).mine(),
      builder: (context, snapshot) {
        final shop = snapshot.data;
        final shopId = shop?['id']?.toString();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Widget page;
        switch (index) {
          case 1:
            page = shopId == null
                ? const _MissingShopPage()
                : SellerProductsPage(shopId: shopId);
            break;
          case 2:
            page = const SellerOrdersPage();
            break;
          case 3:
            page = const SellerFinancePage();
            break;
          default:
            page = const SellerDashboardPage();
        }

        return Scaffold(
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) {
              setState(() => index = value);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Produits',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Commandes',
              ),
              NavigationDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: 'Revenus',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MissingShopPage extends StatelessWidget {
  const _MissingShopPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Produits')),
      body: Center(
        child: Text('Aucune boutique vendeur n’est encore configurée.'),
      ),
    );
  }
}
