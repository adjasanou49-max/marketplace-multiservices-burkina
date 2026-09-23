
class CheckoutState {
  const CheckoutState({
    this.addressId,
    this.deliveryFee = 0,
    this.deliveryDistanceKm,
    this.deliveryStopCount = 0,
    this.couponCode,
  });

  final String? addressId;
  final num deliveryFee;
  final num? deliveryDistanceKm;
  final int deliveryStopCount;
  final String? couponCode;

  CheckoutState copyWith({
    String? addressId,
    num? deliveryFee,
    num? deliveryDistanceKm,
    bool clearDeliveryDistanceKm = false,
    int? deliveryStopCount,
    String? couponCode,
  }) =>
      CheckoutState(
        addressId: addressId ?? this.addressId,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        deliveryDistanceKm:
            clearDeliveryDistanceKm ? null : deliveryDistanceKm ?? this.deliveryDistanceKm,
        deliveryStopCount: deliveryStopCount ?? this.deliveryStopCount,
        couponCode: couponCode ?? this.couponCode,
      );
}
