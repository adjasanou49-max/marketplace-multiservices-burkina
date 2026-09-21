import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/payment_request.dart';

class PaymentRepository {
  const PaymentRepository(this.client);

  final SupabaseClient client;

  Future<String> createPending(PaymentRequest request) async {
    final result = await client.rpc(
      'create_payment_intent',
      params: {
        'p_order_id': request.orderId,
        'p_provider': request.provider,
      },
    );
    return result as String;
  }
}