import '../../cart/domain/cart_item.dart';

class OrderDraft {
  const OrderDraft({required this.items, required this.addressId, required this.subtotal, required this.deliveryFee, this.note});
  final List<CartItem> items;
  final String addressId;
  final num subtotal;
  final num deliveryFee;
  final String? note;
  num get total => subtotal + deliveryFee;
}
