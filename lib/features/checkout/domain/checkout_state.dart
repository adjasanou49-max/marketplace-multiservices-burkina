
class CheckoutState {
  const CheckoutState({
    this.addressId,
    this.deliveryFee = 0,
    this.deliveryDistanceKm,
    this.deliveryStopCount = 0,
    this.note,
    this.couponCode,
  });

  final String? addressId;
  final num deliveryFee;
  final num? deliveryDistanceKm;
  final int deliveryStopCount;
  final String? note;
  final String? couponCode;

  CheckoutState copyWith({
    String? addressId,
    num? deliveryFee,
    num? deliveryDistanceKm,
    int? deliveryStopCount,
    String? note,
    String? couponCode,
  }) =>
      CheckoutState(
        addressId: addressId ?? this.addressId,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        deliveryDistanceKm: deliveryDistanceKm ?? this.deliveryDistanceKm,
        deliveryStopCount: deliveryStopCount ?? this.deliveryStopCount,
        note: note ?? this.note,
        couponCode: couponCode ?? this.couponCode,
      );
}
