class Category {
  const Category({
    required this.id,
    required this.name,
    this.slug,
    this.iconUrl,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? slug;
  final String? iconUrl;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        slug: map['slug'] as String?,
        iconUrl: map['icon_url'] as String?,
        imageUrl: map['image_url'] as String?,
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        isActive: map['is_active'] as bool? ?? true,
      );
}
