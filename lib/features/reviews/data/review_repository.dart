import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewRepository {
  const ReviewRepository(this.client);

  final SupabaseClient client;

  Future<String> create({
    required String productId,
    required String shopId,
    required int rating,
    String? body,
  }) async {
    final result = await client.rpc(
      'create_review',
      params: {
        'p_product_id': productId,
        'p_shop_id': shopId,
        'p_rating': rating,
        'p_body': body,
      },
    );
    return result as String;
  }
}