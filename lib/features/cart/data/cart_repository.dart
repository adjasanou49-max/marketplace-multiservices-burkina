import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/cart_item.dart';

class CartRepository {
  const CartRepository(this.client);

  final SupabaseClient client;

  static final Map<String, Future<String>> _activeCartRequests =
      <String, Future<String>>{};

  Future<String> getOrCreateActiveCart() async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');

    final existingRequest = _activeCartRequests[user.id];
    if (existingRequest != null) return existingRequest;

    final request = _resolveActiveCart(user.id);
    _activeCartRequests[user.id] = request;

    try {
      return await request;
    } finally {
      if (identical(_activeCartRequests[user.id], request)) {
        _activeCartRequests.remove(user.id);
      }
    }
  }

  Future<String> _resolveActiveCart(String userId) async {
    final rows = await client
        .from('carts')
        .select('id,created_at')
        .eq('customer_id', userId)
        .eq('status', 'ACTIVE')
        .order('created_at', ascending: true)
        .limit(1);

    final existing = (rows as List).cast<Map>().firstOrNull;
    if (existing != null) {
      final id = existing['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }

    try {
      final created = await client
          .from('carts')
          .insert({'customer_id': userId, 'status': 'ACTIVE'})
          .select('id')
          .single();
      return created['id'].toString();
    } catch (_) {
      final fallback = await client
          .from('carts')
          .select('id,created_at')
          .eq('customer_id', userId)
          .eq('status', 'ACTIVE')
          .order('created_at', ascending: true)
          .limit(1);

      final first = (fallback as List).cast<Map>().firstOrNull;
      final id = first?['id']?.toString();
      if (id == null || id.isEmpty) rethrow;
      return id;
    }
  }

  Future<void> addItem(CartItem item) async {
    if (item.quantity <= 0) return;

    final cartId = await getOrCreateActiveCart();
    var query = client
        .from('cart_items')
        .select('id,quantity')
        .eq('cart_id', cartId)
        .eq('product_id', item.productId);
    query = item.variantId == null
        ? query.isFilter('variant_id', null)
        : query.eq('variant_id', item.variantId);
    final existing = await query.maybeSingle();

    if (existing == null) {
      await client.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': item.productId,
        'variant_id': item.variantId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      });
      return;
    }

    await client
        .from('cart_items')
        .update({'quantity': (existing['quantity'] as num).toInt() + item.quantity})
        .eq('id', existing['id']);
  }

  Future<void> syncItems(List<CartItem> items) async {
    final cartId = await getOrCreateActiveCart();
    final desired = <String, CartItem>{
      for (final item in items)
        if (item.quantity > 0) item.lineKey: item,
    };

    final existingRows = await client
        .from('cart_items')
        .select('id,product_id,variant_id')
        .eq('cart_id', cartId);

    final existing = <String, String>{};
    for (final raw in (existingRows as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final productId = row['product_id']?.toString();
      final variantId = row['variant_id']?.toString();
      final id = row['id']?.toString();
      if (productId != null &&
          productId.isNotEmpty &&
          id != null &&
          id.isNotEmpty) {
        existing[[productId, variantId ?? ''].join('::')] = id;
      }
    }

    for (final entry in desired.entries) {
      final item = entry.value;
      final rowId = existing[entry.key];

      if (rowId == null) {
        await client.from('cart_items').insert({
          'cart_id': cartId,
          'product_id': item.productId,
          'variant_id': item.variantId,
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