import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_order_repository.dart';

class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes vendeur')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: client == null ? null : SellerOrderRepository(client).mine(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const Center(child: Text('Aucune commande'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final row = rows[index];
              final orderId = row['order_id']?.toString() ?? '';
              final shortOrderId = orderId.length > 8
                  ? orderId.substring(0, 8)
                  : orderId;
              return ListTile(
                title: Text('Commande #$shortOrderId'),
                subtitle: Text(
                  'Statut: ${row['status'] ?? '—'} • Sous-total: ${row['subtotal'] ?? 0} XOF',
                ),
                onTap: () => GoRouter.of(context)
                    .push('/seller/order/${row['id']}'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          );
        },
      ),
    );
  }
}
