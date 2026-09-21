import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/application/cart_controller.dart';
import '../../cart/domain/cart_item.dart';
import '../../follows/application/follow_controller.dart';
import '../domain/product.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = product.price;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(context).push(
          '/product/${product.id}',
          extra: product,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: product.imageUrl == null
                  ? const ColoredBox(
                      color: Color(0xFFF3F4F6),
                      child: Icon(Icons.image_outlined, size: 40),
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFF3F4F6),
                        child: Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: price == null
                        ? const SizedBox()
                        : Text(
                            '${price.toStringAsFixed(0)} ${product.currency}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                  if (product.isActive)
                    IconButton(
                      tooltip: 'Ajouter aux favoris',
                      onPressed: () async {
                        final repository = ref.read(followRepositoryProvider);
                        if (repository == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Supabase non configuré.')),
                          );
                          return;
                        }
                        try {
                          final added = await repository.toggleProduct(product.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added ? 'Ajouté aux favoris.' : 'Retiré des favoris.',
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur : $error')),
                          );
                        }
                      },
                      icon: const Icon(Icons.favorite_border),
                    ),
                  if (price != null)
                    IconButton(
                      tooltip: 'Ajouter au panier',
                      onPressed: () {
                        ref.read(cartControllerProvider.notifier).add(
                          CartItem(
                            productId: product.id,
                            quantity: 1,
                            unitPrice: price,
                            name: product.name,
                            imageUrl: product.imageUrl,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Produit ajouté au panier.')),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}