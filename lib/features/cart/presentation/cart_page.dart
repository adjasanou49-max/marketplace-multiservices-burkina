import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/cart_controller.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartControllerProvider);
    final total = ref.watch(cartTotalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: items.isEmpty
          ? const Center(child: Text('Votre panier est vide'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final current = items[index];
                return Card(
                  child: ListTile(
                    title: Text(current.name),
                    subtitle: Text('${current.unitPrice.toStringAsFixed(0)} XOF'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => ref.read(cartControllerProvider.notifier)
                              .setQuantity(current.productId, current.quantity - 1, variantId: current.variantId),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${current.quantity}'),
                        IconButton(
                          onPressed: () => ref.read(cartControllerProvider.notifier)
                              .setQuantity(current.productId, current.quantity + 1, variantId: current.variantId),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () => context.push('/checkout'),
            child: Text('Continuer — ${total.toStringAsFixed(0)} XOF'),
          ),
        ),
      ),
    );
  }
}
