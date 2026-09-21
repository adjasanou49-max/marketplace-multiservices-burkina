class CheckoutState {
  const CheckoutState({this.addressId, this.deliveryFee = 0, this.note});
  final String? addressId;
  final num deliveryFee;
  final String? note;
  CheckoutState copyWith({String? addressId, num? deliveryFee, String? note}) => CheckoutState(
    addressId: addressId ?? this.addressId, deliveryFee: deliveryFee ?? this.deliveryFee, note: note ?? this.note,
  );
}
