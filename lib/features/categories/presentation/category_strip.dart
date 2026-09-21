import 'package:flutter/material.dart';

import '../domain/category.dart';

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key, required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            width: 72,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: category.imageUrl == null
                      ? null
                      : NetworkImage(category.imageUrl!),
                  child: category.imageUrl == null
                      ? const Icon(Icons.category_outlined)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
