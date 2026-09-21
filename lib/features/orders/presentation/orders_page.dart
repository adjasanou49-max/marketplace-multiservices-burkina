import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/order_query_repository.dart';

final myOrdersProvider = FutureProvider<List<OrderSummary>>((ref) async {
  final client = ref.watch(supabaseProvider);
  if (client == null) return const [];
  return OrderQueryRepository(client).mine();
});

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(myOrdersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myOrdersProvider);
          },
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 220),
                    Center(child: Text('Aucune commande')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final order = items[index];
                    final shortId = order.id.length > 8
                        ? order.id.substring(0, 8)
                        : order.id;
                    return Card(
                      child: ListTile(
                        title: Text('Commande #$shortId'),
                        subtitle: Text(order.status),
                        trailing: Text(
                          '${order.total.toStringAsFixed(0)} ${order.currency}',
                        ),
                        onTap: () => GoRouter.of(context).push(
                          '/order/${order.id}',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await OrderQueryRepository(client).cancelUnpaid(orderId);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Commande annulée.')),
      );
      ref.invalidate(myOrdersProvider);
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Annulation impossible : $error')),
      );
    }
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
      appBar: AppBar(title: const Text('Détail commande')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: OrderQueryRepository(client).detail(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Commande introuvable.'));
          }
          final order = Map<String, dynamic>.from(data['order'] as Map);
          final groups = (data['groups'] as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final items = (data['items'] as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final packages = (data['packages'] as List? ?? const [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
          final status = order['status']?.toString() ?? '—';
          final canCancel =
              status == 'PENDING_PAYMENT' || status == 'PAID';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Commande #$orderId',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Statut : $status'),
              Text(
                'Total : ${order['total'] ?? 0} ${order['currency'] ?? 'XOF'}',
              ),
              if (packages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Livraison',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                for (final package in packages) ...[
                  Builder(
                    builder: (context) {
                      final assignment = package['assignment'] is Map
                          ? Map<String, dynamic>.from(package['assignment'])
                          : const <String, dynamic>{};
                      final courierId = assignment['courier_id']?.toString();
                      final packageStatus = package['status']?.toString() ?? '—';
                      if (courierId == null || courierId.isEmpty) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_shipping_outlined),
                          title: Text('Colis • $packageStatus'),
                          subtitle: const Text('En attente d’un livreur'),
                        );
                      }
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping_outlined),
                          title: Text('Colis • $packageStatus'),
                          subtitle: Text(
                            'Livreur • ${assignment['status'] ?? 'ASSIGNED'}',
                          ),
                          trailing: FilledButton.tonal(
                            onPressed: () => GoRouter.of(context).push(
                              '/delivery/$orderId/$courierId',
                            ),
                            child: const Text('Suivre'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],              const Divider(height: 28),
              for (final group in groups) ...[
                Text(
                  group['shops'] is Map
                      ? (group['shops']['name']?.toString() ?? 'Boutique')
                      : 'Boutique',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final item in items.where(
                  (item) => item['order_group_id'] == group['id'],
                ))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item['product_name']?.toString() ?? 'Produit',
                    ),
                    subtitle: Text('Quantité : ${item['quantity'] ?? 0}'),
                    trailing: group['status']?.toString() == 'DELIVERED'
                        ? IconButton(
                            tooltip: 'Donner un avis',
                            icon: const Icon(Icons.rate_review_outlined),
                            onPressed: () {
                              final productId = item['product_id']?.toString() ?? '';
                              final shopId = group['shop_id']?.toString() ?? '';
                              if (productId.isEmpty || shopId.isEmpty) return;
                              final uri = Uri(
                                path: '/review/$productId',
                                queryParameters: {
                                  'shopId': shopId,
                                  'name': item['product_name']?.toString() ?? 'Produit',
                                },
                              );
                              GoRouter.of(context).push(uri.toString());
                            },
                          )
                        : Text('${item['total_price'] ?? 0} XOF'),
                  ),
                const SizedBox(height: 10),
              ],
              if (canCancel)
                FilledButton.tonal(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Annuler la commande'),
                ),
            ],
          );
        },
      ),
    );
  }
}