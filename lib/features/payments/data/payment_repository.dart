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

  Future<Map<String, dynamic>> createPaymentSession({
    required String orderId,
    required String provider,
  }) async {
    late final String functionName;
    final Map<String, dynamic> body = {'order_id': orderId};

    switch (provider) {
      case 'WAVE':
        functionName = 'create-wave-payment-session-v3';
        break;
      case 'CINETPAY':
        functionName = 'create-cinetpay-payment-session-v3';
        body['provider'] = 'CINETPAY';
        break;
      default:
        throw StateError('Mode de paiement non pris en charge.');
    }

    final response = await client.functions.invoke(
      functionName,
      body: body,
    );

    if (response.data is! Map) {
      throw StateError('Réponse de paiement invalide.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final checkoutUrl = data['checkout_url']?.toString().trim() ?? '';
    if (checkoutUrl.isEmpty) {
      final error = data['message']?.toString() ?? data['error']?.toString();
      throw StateError(
        error == null || error.isEmpty
            ? 'Lien de paiement indisponible.'
            : error,
      );
    }

    return data;
  }
}
