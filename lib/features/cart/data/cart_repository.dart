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
    final desired = <String, CartItem>{
      for (final item in items)
        if (item.quantity > 0) item.productId: item,
    };

    final existingRows = await client
        .from('cart_items')
        .select('id,product_id')
        .eq('cart_id', cartId);

    final existing = <String, String>{};
    for (final raw in (existingRows as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final productId = row['product_id']?.toString();
      final id = row['id']?.toString();
      if (productId != null && productId.isNotEmpty && id != null && id.isNotEmpty) {
        existing[productId] = id;
      }
    }

    for (final entry in desired.entries) {
      final item = entry.value;
      final rowId = existing[entry.key];

      if (rowId == null) {
        await client.from('cart_items').insert({
          'cart_id': cartId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        });
      } else {
        await client.from('cart_items').update({
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        }).eq('id', rowId);
      }
    }

    final staleIds = existing.entries
        .where((entry) => !desired.containsKey(entry.key))
        .map((entry) => entry.value)
        .toList();

    if (staleIds.isNotEmpty) {
      await client.from('cart_items').delete().inFilter('id', staleIds);
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
