import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/cart_item.dart';

class CartRepository {
  const CartRepository(this.client);

  final SupabaseClient client;

  Future<String> getOrCreateActiveCart() async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');

    final existing = await client
        .from('carts')
        .select('id')
        .eq('customer_id', user.id)
        .eq('status', 'ACTIVE')
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final created = await client
        .from('carts')
        .insert({'customer_id': user.id, 'status': 'ACTIVE'})
        .select('id')
        .single();

    return created['id'] as String;
  }

  Future<void> addItem(CartItem item) async {
    if (item.quantity <= 0) return;

    final cartId = await getOrCreateActiveCart();
    final existing = await client
        .from('cart_items')
        .select('id,quantity')
        .eq('cart_id', cartId)
        .eq('product_id', item.productId)
        .maybeSingle();

    if (existing == null) {
      await client.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      });
      return;
    }

    await client
        .from('cart_items')
        .update({'quantity': (existing['quantity'] as int) + item.quantity})
        .eq('id', existing['id']);
  }

  Future<void> syncItems(List<CartItem> items) async {
    final cartId = await getOrCreateActiveCart();

    await client.from('cart_items').delete().eq('cart_id', cartId);
    if (items.isEmpty) return;

    final payload = items
        .where((item) => item.quantity > 0)
        .map(
          (item) => {
            'cart_id': cartId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
          },
        )
        .toList();

    if (payload.isNotEmpty) {
      await client.from('cart_items').insert(payload);
    }
  }

  Future<String> checkout({
    required Map<String, dynamic> deliveryAddress,
    num deliveryFee = 0,
    String? couponCode,
    String? idempotencyKey,
  }) async {
    final cartId = await getOrCreateActiveCart();
    final result = await client.rpc(
      'checkout_cart',
      params: {
        'p_cart_id': cartId,
        'p_delivery_address': deliveryAddress,
        'p_delivery_fee': deliveryFee,
        'p_coupon_code': couponCode,
        'p_idempotency_key':
            idempotencyKey ?? DateTime.now().microsecondsSinceEpoch.toString(),
      },
    );
    return result as String;
  }
}
