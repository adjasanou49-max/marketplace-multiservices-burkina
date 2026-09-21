import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cart/data/cart_repository.dart';
import '../domain/order_draft.dart';

class OrderRepository {
  const OrderRepository(this.client);

  final SupabaseClient client;

  Future<String> createOrder(OrderDraft draft) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');

    final address = await client
        .from('delivery_addresses')
        .select()
        .eq('id', draft.addressId)
        .eq('customer_id', user.id)
        .single();

    final cart = CartRepository(client);
    await cart.syncItems(draft.items);

    return cart.checkout(
      deliveryAddress: Map<String, dynamic>.from(address),
      deliveryFee: draft.deliveryFee,
    );
  }
}
