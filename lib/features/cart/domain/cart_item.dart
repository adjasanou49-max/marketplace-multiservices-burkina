class CartItem {
  const CartItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.name,
    this.imageUrl,
    this.variantId,
  });

  final String productId;
  final String? variantId;
  final int quantity;
  final num unitPrice;
  final String name;
  final String? imageUrl;

  num get total => unitPrice * quantity;

  String get lineKey => '$productId::${variantId ?? ''}';

  CartItem copyWith({
    String? variantId,
    int? quantity,
  }) =>
      CartItem(
        productId: productId,
        variantId: variantId ?? this.variantId,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        name: name,
        imageUrl: imageUrl,
      );
}
