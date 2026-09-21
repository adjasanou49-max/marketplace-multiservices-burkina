import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/seller_shop_repository.dart';
import 'seller_create_shop_page.dart';
import 'seller_dashboard_page.dart';
import 'seller_orders_page.dart';
import 'seller_products_page.dart';
import 'seller_shop_page.dart';
import 'seller_tools_page.dart';

class SellerNavigation extends ConsumerStatefulWidget {
  const SellerNavigation({super.key});

  @override
  ConsumerState<SellerNavigation> createState() => _SellerNavigationState();
}

class _SellerNavigationState extends ConsumerState<SellerNavigation> {
  int index = 0;
  late Future<Map<String, dynamic>?> shopFuture;

  @override
  void initState() {
    super.initState();
    shopFuture = _loadShop();
  }

  Future<Map<String, dynamic>?> _loadShop() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return null;
    return SellerShopRepository(client).mine();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>( 
      future: shopFuture,
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
            page = shop == null
                ? _MissingShopPage(
                    onCreate: () async {
                      final created = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const SellerCreateShopPage(),
                        ),
                      );
                      if (created == true && mounted) {
                        setState(() => shopFuture = _loadShop());
                      }
                    },
                  )
                : SellerShopPage(shop: shop);
            break;
          case 2:
            page = shopId == null
                ? const _MissingShopPage(title: 'Produits')
                : SellerProductsPage(shopId: shopId);
            break;
          case 3:
            page = const SellerOrdersPage();
            break;
          case 4:
            page = const SellerToolsPage();
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
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store),
                label: 'Boutique',
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
                icon: Icon(Icons.more_horiz),
                selectedIcon: Icon(Icons.more_horiz),
                label: 'Plus',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MissingShopPage extends StatelessWidget {
  const _MissingShopPage({
    this.title = 'Boutique',
    this.onCreate,
  });

  final String title;
  final Future<void> Function()? onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aucune boutique vendeur n’est encore configurée.'),
            if (onCreate != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Créer ma boutique'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}