import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../follows/application/follow_controller.dart';
import '../domain/shop.dart';
import '../application/shop_controller.dart';

class ShopDetailPage extends ConsumerWidget {
  const ShopDetailPage({
    super.key,
    this.shop,
    this.shopId,
  }) : assert(shop != null || shopId != null);

  final Shop? shop;
  final String? shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shop != null) {
      return _buildShop(context, ref, shop!);
    }

    final state = ref.watch(shopByIdProvider(shopId!));
    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Boutique')),
        body: Center(child: Text('Erreur : $error')),
      ),
      data: (item) => item == null
          ? const Scaffold(
              body: Center(child: Text('Boutique introuvable')),
            )
          : _buildShop(context, ref, item),
    );
  }

  Widget _buildShop(BuildContext context, WidgetRef ref, Shop shop) {
    return Scaffold(
      appBar: AppBar(title: Text(shop.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (shop.coverUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(
                  shop.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage:
                    shop.logoUrl == null ? null : NetworkImage(shop.logoUrl!),
                child: shop.logoUrl == null
                    ? const Icon(Icons.storefront, size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shop.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Suivre',
                onPressed: () async {
                  final repository = ref.read(followRepositoryProvider);
                  if (repository == null) return;
                  try {
                    final followed = await repository.toggleShop(shop.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          followed ? 'Boutique suivie.' : 'Boutique non suivie.',
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
            ],
          ),
          const SizedBox(height: 20),
          Text(shop.description?.trim().isNotEmpty == true ? shop.description! : 'Aucune description.'),
          const SizedBox(height: 20),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.verified_outlined),
            title: Text('Vérification'),
            subtitle: Text('Informations de la boutique'),
          ),
        ],
      ),
    );
  }
}