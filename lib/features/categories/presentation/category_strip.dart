import 'package:flutter/material.dart';

import '../domain/category.dart';

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.categories,
    this.selectedIndex = 0,
    this.onSelected,
  });

  final List<Category> categories;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = index == selectedIndex;
          return SizedBox(
            width: 74,
            child: Semantics(
              button: onSelected != null,
              selected: selected,
              label: category.name,
              child: InkWell(
                borderRadius: BorderRadius.circular(38),
                onTap: onSelected == null ? null : () => onSelected!(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: selected ? 3 : 1,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: category.imageUrl == null
                              ? null
                              : NetworkImage(category.imageUrl!),
                          child: category.imageUrl == null
                              ? const Icon(Icons.category_outlined)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
