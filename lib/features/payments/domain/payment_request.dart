class PaymentRequest {
  const PaymentRequest({required this.orderId, required this.provider, required this.amount, this.currency = 'XOF'});
  final String orderId;
  final String provider;
  final num amount;
  final String currency;
}
