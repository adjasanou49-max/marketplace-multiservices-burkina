import 'package:flutter/material.dart';
import 'seller_dashboard_page.dart';

class SellerNavigation extends StatefulWidget {
  const SellerNavigation({super.key});
  @override
  State<SellerNavigation> createState() => _SellerNavigationState();
}
class _SellerNavigationState extends State<SellerNavigation> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: const SellerDashboardPage(),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Accueil'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Produits'),
        NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: 'Commandes'),
        NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Revenus'),
      ],
    ),
  );
}