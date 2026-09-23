import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/domain/cart_item.dart';
import '../application/product_controller.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({
    super.key,
    this.product,
    this.productId,
  }) : assert(product != null || productId != null);

  final Product? product;
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (product != null) {
      return _buildProduct(context, ref, product!);
    }

    final state = ref.watch(productByIdProvider(productId!));
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Produit')),
        body: Center(child: Text('Erreur : $error')),
      ),
      data: (item) => item == null
          ? const Scaffold(
              body: Center(child: Text('Produit introuvable')),
            )
          : _buildProduct(context, ref, item),
    );
  }

  Widget _buildProduct(BuildContext context, WidgetRef ref, Product product) {
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
        Text('${price.toStringAsFixed(0)} ${product.currency}', style: Theme.of(context).textTheme.titleLarge),
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
