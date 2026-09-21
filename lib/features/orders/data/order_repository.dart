import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/order_draft.dart';

class OrderRepository {
  const OrderRepository(this.client);
  final SupabaseClient client;

  Future<String> createOrder(OrderDraft draft) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');
    final row = await client.from('orders').insert({
      'customer_id': user.id,
      'subtotal': draft.subtotal,
      'delivery_fee': draft.deliveryFee,
      'total_amount': draft.total,
      'delivery_address_id': draft.addressId,
      'customer_note': draft.note,
    }).select('id').single();
    return row['id'] as String;
  }
}
