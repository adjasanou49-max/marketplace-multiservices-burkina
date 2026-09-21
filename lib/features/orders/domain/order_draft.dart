import '../../cart/domain/cart_item.dart';

class OrderDraft {
  const OrderDraft({
    required this.items,
    required this.addressId,
    required this.subtotal,
    required this.deliveryFee,
    this.note,
    this.couponCode,
    this.idempotencyKey,
  });

  final List<CartItem> items;
  final String addressId;
  final num subtotal;
  final num deliveryFee;
  final String? note;
  final String? couponCode;
  final String? idempotencyKey;

  num get total => subtotal + deliveryFee;
}