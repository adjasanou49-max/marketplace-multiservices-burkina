import 'package:flutter/material.dart';
import '../domain/shop.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: shop.logoUrl == null ? null : NetworkImage(shop.logoUrl!),
          child: shop.logoUrl == null ? const Icon(Icons.storefront) : null,
        ),
        title: Text(shop.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(shop.verificationStatus == null ? 'Boutique' : 'Boutique ${shop.verificationStatus}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
