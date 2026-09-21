import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/seller_controller.dart';

class SellerDashboardPage extends ConsumerWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerDashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Espace vendeur')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (dashboard) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _tile('Boutiques', dashboard.shopCount.toString(), Icons.store),
            _tile(
              'Produits',
              dashboard.productCount.toString(),
              Icons.inventory_2_outlined,
            ),
            _tile(
              'Commandes en attente',
              dashboard.pendingOrders.toString(),
              Icons.shopping_bag_outlined,
            ),
            _tile(
              'Revenus',
              '${dashboard.revenue} XOF',
              Icons.payments_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String value, IconData icon) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
}
