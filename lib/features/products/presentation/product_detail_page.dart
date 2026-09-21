import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/domain/cart_item.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = product.price ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Produit')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AspectRatio(
          aspectRatio: 1,
          child: product.imageUrl == null
              ? const ColoredBox(color: Color(0xFFF3F4F6), child: Icon(Icons.image_outlined, size: 64))
              : Image.network(product.imageUrl!, fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),
        Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('\${price.toStringAsFixed(0)} \${product.currency}', style: Theme.of(context).textTheme.titleLarge),
        if (product.description != null) ...[const SizedBox(height: 16), Text(product.description!)],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: product.price == null ? null : () {
            ref.read(cartControllerProvider.notifier).add(CartItem(
              productId: product.id, quantity: 1, unitPrice: price, name: product.name, imageUrl: product.imageUrl,
            ));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit ajouté au panier')));
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Ajouter au panier'),
        ),
      ]),
    );
  }
}
