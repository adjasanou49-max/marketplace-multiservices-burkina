
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cart/data/cart_repository.dart';

class DeliveryQuote {
  const DeliveryQuote({
    required this.customerFee,
    required this.distanceKm,
    required this.stopCount,
    required this.currency,
  });

  final num customerFee;
  final num distanceKm;
  final int stopCount;
  final String currency;

  factory DeliveryQuote.fromMap(Map<String, dynamic> map) {
    return DeliveryQuote(
      customerFee: (map['customer_fee'] as num?) ?? 0,
      distanceKm: (map['distance_km'] as num?) ?? 0,
      stopCount: (map['stop_count'] as num?)?.toInt() ?? 0,
      currency: map['currency']?.toString() ?? 'XOF',
    );
  }
}

class DeliveryQuoteRepository {
  const DeliveryQuoteRepository(this.client);

  final SupabaseClient client;

  Future<DeliveryQuote> quote({
    required String cartId,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    final result = await client.rpc(
      'calculate_delivery_fee',
      params: {
        'p_cart_id': cartId,
        'p_delivery_address': deliveryAddress,
      },
    );

    return DeliveryQuote.fromMap(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<String> activeCartId() {
    return CartRepository(client).getOrCreateActiveCart();
  }
}
