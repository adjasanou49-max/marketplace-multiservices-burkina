import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/payment_request.dart';

class PaymentRepository {
  const PaymentRepository(this.client);
  final SupabaseClient client;

  Future<String> createPending(PaymentRequest request) async {
    final row = await client.from('payments').insert({
      'order_id': request.orderId,
      'provider': request.provider,
      'amount': request.amount,
      'currency': request.currency,
      'status': 'PENDING',
      'metadata': <String, dynamic>{},
    }).select('id').single();
    return row['id'] as String;
  }
}
