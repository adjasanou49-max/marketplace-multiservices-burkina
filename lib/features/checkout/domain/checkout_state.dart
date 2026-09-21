class CheckoutState {
  const CheckoutState({
    this.addressId,
    this.deliveryFee = 0,
    this.note,
    this.couponCode,
  });

  final String? addressId;
  final num deliveryFee;
  final String? note;
  final String? couponCode;

  CheckoutState copyWith({
    String? addressId,
    num? deliveryFee,
    String? note,
    String? couponCode,
  }) =>
      CheckoutState(
        addressId: addressId ?? this.addressId,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        note: note ?? this.note,
        couponCode: couponCode ?? this.couponCode,
      );
}