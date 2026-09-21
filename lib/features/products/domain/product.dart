class Product {
  const Product({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.price,
    this.currency = 'XOF',
    this.imageUrl,
    this.categoryId,
    this.shopId,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? slug;
  final String? description;
  final num? price;
  final String currency;
  final String? imageUrl;
  final String? categoryId;
  final String? shopId;
  final bool isActive;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        slug: map['slug'] as String?,
        description: map['description'] as String?,
        price: map['price'] as num?,
        currency: map['currency'] as String? ?? 'XOF',
        imageUrl: map['image_url'] as String?,
        categoryId: map['category_id'] as String?,
        shopId: map['shop_id'] as String?,
        isActive: map['status'] == null || map['status'] == 'ACTIVE',
      );
}
