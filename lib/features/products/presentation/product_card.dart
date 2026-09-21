import 'package:flutter/material.dart';
import '../domain/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
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
                : Image.network(product.imageUrl!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                if (product.price != null)
                  Text(
                    '${product.price!.toStringAsFixed(0)} ${product.currency}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
