import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_multiservices_burkina/features/products/domain/product.dart';

void main() {
  test('maps an active product using the current database fields', () {
    final product = Product.fromMap({
      'id': 'product-1',
      'name': 'Robe',
      'slug': 'robe',
      'description': 'Description',
      'price': 12500,
      'currency': 'XOF',
      'image_url': 'https://example.invalid/image.webp',
      'category_id': 'category-1',
      'shop_id': 'shop-1',
      'status': 'ACTIVE',
    });

    expect(product.id, 'product-1');
    expect(product.name, 'Robe');
    expect(product.price, 12500);
    expect(product.currency, 'XOF');
    expect(product.imageUrl, 'https://example.invalid/image.webp');
    expect(product.isActive, isTrue);
  });

  test('does not treat an inactive product as active', () {
    final product = Product.fromMap({
      'id': 'product-2',
      'name': 'Article',
      'price': 500,
      'status': 'INACTIVE',
    });

    expect(product.isActive, isFalse);
  });
}
