import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_order_repository.dart';

class SellerOrderDetailPage extends ConsumerWidget {
  const SellerOrderDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Détail commande')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: client == null
            ? null
            : SellerOrderRepository(client).detail(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const SizedBox();
          }

          final rawGroup = data['group'];
          final rawItems = data['items'];
          final group = rawGroup is Map
              ? Map<String, dynamic>.from(rawGroup)
              : <String, dynamic>{};
          final items = rawItems is List
              ? rawItems
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
              : const <Map<String, dynamic>>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Statut: ${group['status'] ?? '—'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Sous-total: ${group['subtotal'] ?? 0} XOF'),
              const Divider(),
              for (final item in items)
                ListTile(
                  title: Text(item['product_name']?.toString() ?? 'Produit'),
                  subtitle: Text('Quantité: ${item['quantity'] ?? 0}'),
                  trailing: Text('${item['total_price'] ?? 0} XOF'),
                ),
            ],
          );
        },
      ),
    );
  }
}
