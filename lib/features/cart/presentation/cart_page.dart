import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() {
    final repo = ref.read(cartRepositoryProvider);
    if (repo == null) return Future.value(null);
    return repo.activeCart();
  }

  Future<void> _changeQuantity(
    Map<String, dynamic> item,
    int quantity,
  ) async {
    final repo = ref.read(cartRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.setQuantity(
        cartItemId: item['id'].toString(),
        quantity: quantity,
      );

      if (!mounted) return;
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mise à jour impossible : ' + error.toString(),
          ),
        ),
      );
    }
  }

  double _total(Map<String, dynamic> cart) {
    final items = cart['items'];
    if (items is! List) return 0;

    return items.fold<double>(0, (sum, raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      final price =
          double.tryParse(item['unit_price']?.toString() ?? '') ?? 0;
      final quantity =
          int.tryParse(item['quantity']?.toString() ?? '') ?? 0;
      return sum + (price * quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    final signedIn = client?.auth.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          IconButton(
            tooltip: 'Mes commandes',
            onPressed: () => context.push('/orders'),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: !signedIn
          ? Center(
              child: FilledButton(
                onPressed: () => context.push('/auth'),
                child: const Text('Se connecter'),
              ),
            )
          : FutureBuilder<Map<String, dynamic>?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur du panier : ' + snapshot.error.toString(),
                    ),
                  );
                }

                final cart = snapshot.data;
                final rawItems = cart?['items'];
                final items = rawItems is List ? rawItems : const [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Votre panier est vide.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length + 2,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    if (index == items.length) {
                      return ListTile(
                        title: const Text('Sous-total'),
                        trailing: Text(
                          _total(cart!).toStringAsFixed(0) + ' XOF',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    if (index == items.length + 1) {
                      return FilledButton.icon(
                        onPressed: () =>
                            context.push('/checkout/' + cart!['id'].toString()),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Choisir la livraison et payer'),
                      );
                    }

                    final item =
                        Map<String, dynamic>.from(items[index] as Map);
                    final product = item['products'] is Map
                        ? Map<String, dynamic>.from(item['products'] as Map)
                        : const <String, dynamic>{};
                    final quantity =
                        int.tryParse(item['quantity']?.toString() ?? '') ?? 1;

                    return Card(
                      child: ListTile(
                        title: Text(
                          product['name']?.toString() ?? 'Produit',
                        ),
                        subtitle: Text(
                          (item['unit_price']?.toString() ?? '0') + ' XOF',
                        ),
                        trailing: SizedBox(
                          width: 132,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _changeQuantity(item, quantity - 1),
                                icon: const Icon(Icons.remove),
                              ),
                              Text('$quantity'),
                              IconButton(
                                onPressed: () =>
                                    _changeQuantity(item, quantity + 1),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
