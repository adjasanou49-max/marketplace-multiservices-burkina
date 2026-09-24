import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentHistoryRepository {
  const PaymentHistoryRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> mine() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final rows = await client
        .from('payments')
        .select(
          'id,order_id,provider,provider_reference,amount,currency,status,'
          'created_at,orders!inner(customer_id)',
        )
        .eq('orders.customer_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
