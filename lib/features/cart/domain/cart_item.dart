class CartItem {
  const CartItem({required this.productId, required this.quantity, required this.unitPrice, required this.name, this.imageUrl});
  final String productId;
  final int quantity;
  final num unitPrice;
  final String name;
  final String? imageUrl;
  num get total => unitPrice * quantity;
  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId, quantity: quantity ?? this.quantity, unitPrice: unitPrice, name: name, imageUrl: imageUrl,
  );
}
