import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class SellerOrdersPage extends ConsumerStatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  ConsumerState<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends ConsumerState<SellerOrdersPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;

    if (client == null || user == null) return const [];

    final sellerRows = await client
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if ((sellerRows as List).isEmpty) return const [];

    final sellerId = (sellerRows.first as Map)['id'].toString();

    final shopRows = await client
        .from('shops')
        .select('id,name')
        .eq('seller_id', sellerId);

    final shopIds = (shopRows as List)
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .toList();

    if (shopIds.isEmpty) return const [];

    final groups = await client
        .from('order_groups')
        .select(
          'id,order_id,shop_id,status,subtotal,created_at,shops(name),order_items(product_name,quantity,unit_price,total_price)',
        )
        .inFilter('shop_id', shopIds)
        .order('created_at', ascending: false)
        .limit(200);

    return (groups as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(supabaseProvider)?.auth.currentUser != null;

    if (!signedIn) {
      return const Scaffold(
        body: Center(
          child: Text('Connectez-vous à votre compte vendeur.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes vendeur'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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

          final groups =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (groups.isEmpty) {
            return const Center(
              child: Text('Aucune commande pour vos boutiques.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final group = groups[index];
                final shop = group['shops'] is Map
                    ? Map<String, dynamic>.from(group['shops'] as Map)
                    : const <String, dynamic>{};
                final rawItems = group['order_items'];
                final items = rawItems is List ? rawItems : const [];

                return Card(
                  child: ExpansionTile(
                    title: Text(
                      shop['name']?.toString() ?? 'Boutique',
                    ),
                    subtitle: Text(
                      'Commande : ' +
                          (group['order_id']?.toString() ?? '-') +
                          '\nÉtat : ' +
                          (group['status']?.toString() ?? '-') +
                          ' • Sous-total : ' +
                          (group['subtotal']?.toString() ?? '0') +
                          ' XOF',
                    ),
                    children: [
                      for (final rawItem in items)
                        Builder(
                          builder: (context) {
                            final item =
                                Map<String, dynamic>.from(rawItem as Map);

                            return ListTile(
                              title: Text(
                                item['product_name']?.toString() ??
                                    'Produit',
                              ),
                              subtitle: Text(
                                'Qté : ' +
                                    (item['quantity']?.toString() ?? '0') +
                                    ' • ' +
                                    (item['unit_price']?.toString() ?? '0') +
                                    ' XOF',
                              ),
                              trailing: Text(
                                (item['total_price']?.toString() ?? '0') +
                                    ' XOF',
                              ),
                            );
                          },
                        ),
                    ],
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
