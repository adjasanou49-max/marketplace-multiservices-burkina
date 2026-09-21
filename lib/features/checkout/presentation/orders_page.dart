import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/checkout_repository.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final repo = ref.read(checkoutRepositoryProvider);
    if (repo == null) return Future.value(const []);
    return repo.orders(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);

    if (client?.auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Connectez-vous pour voir vos commandes.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur des commandes : ' + snapshot.error.toString(),
              ),
            );
          }

          final orders =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (orders.isEmpty) {
            return const Center(
              child: Text('Aucune commande pour le moment.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final order = orders[index];
                final status = order['status']?.toString() ?? '';
                final orderId = order['order_id']?.toString() ?? '';

                final trackable =
                    status != 'PENDING_PAYMENT' &&
                    status != 'CANCELLED' &&
                    status != 'REFUNDED';

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long_outlined),
                    ),
                    title: Text(orderId),
                    subtitle: Text(
                      status +
                          ' • ' +
                          (order['created_at']?.toString() ?? ''),
                    ),
                    trailing: Text(
                      (order['total']?.toString() ?? '0') +
                          ' ' +
                          (order['currency']?.toString() ?? 'XOF'),
                    ),
                    onTap: trackable && orderId.isNotEmpty
                        ? () => context.push('/delivery/' + orderId)
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
