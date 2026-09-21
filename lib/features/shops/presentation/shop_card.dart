import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../follows/application/follow_controller.dart';
import '../domain/shop.dart';

class ShopCard extends ConsumerWidget {
  const ShopCard({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => GoRouter.of(context).push('/shop/${shop.id}', extra: shop),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage:
                shop.logoUrl == null ? null : NetworkImage(shop.logoUrl!),
            child: shop.logoUrl == null
                ? const Icon(Icons.storefront)
                : null,
          ),
          title: Text(shop.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            shop.verificationStatus == null
                ? 'Boutique'
                : 'Boutique ${shop.verificationStatus}',
          ),
          trailing: IconButton(
            tooltip: 'Suivre la boutique',
            icon: const Icon(Icons.favorite_border),
            onPressed: () async {
              final repository = ref.read(followRepositoryProvider);
              if (repository == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Supabase non configuré.')),
                );
                return;
              }
              try {
                final followed = await repository.toggleShop(shop.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      followed
                          ? 'Boutique suivie.'
                          : 'Boutique retirée des suivis.',
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
          ),
        ),
      ),
    );
  }
}