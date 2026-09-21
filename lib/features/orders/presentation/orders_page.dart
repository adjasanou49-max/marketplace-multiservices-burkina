import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_query_repository.dart';
import '../../../core/providers/repository_providers.dart';

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
      appBar: AppBar(title: const Text('Mes commandes')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Aucune commande'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final o = items[i];
                  return Card(
                    child: ListTile(
                      title: Text('Commande ${o.id.substring(0, 8)}'),
                      subtitle: Text(o.status),
                      trailing: Text('${o.total} ${o.currency}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
