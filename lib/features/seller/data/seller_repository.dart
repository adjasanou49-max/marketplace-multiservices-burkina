import 'package:supabase_flutter/supabase_flutter.dart';

class SellerRepository {
  const SellerRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> dashboard() async {
    final raw = await client.rpc('get_seller_dashboard');

    if (raw is! List) return const [];

    return raw
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<String?> sellerId() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final rows = await client
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if ((rows as List).isEmpty) return null;
    return (rows.first as Map)['id']?.toString();
  }

  Future<num> balance(String sellerId) async {
    final rows = await client
        .from('seller_ledger')
        .select('amount')
        .eq('seller_id', sellerId);

    return (rows as List).fold<num>(
      0,
      (sum, row) =>
          sum + (num.tryParse((row as Map)['amount']?.toString() ?? '') ?? 0),
    );
  }

  Future<String> requestPayout({
    required String sellerId,
    required num amount,
    required String provider,
  }) async {
    final raw = await client.rpc(
      'request_seller_payout_secure',
      params: {
        'p_seller_id': sellerId,
        'p_amount': amount,
        'p_provider': provider,
      },
    );

    return raw.toString();
  }

  Future<List<Map<String, dynamic>>> payouts(String sellerId) async {
    final rows = await client
        .from('seller_payouts')
        .select(
          'id,amount,currency,provider,status,requested_at,paid_at',
        )
        .eq('seller_id', sellerId)
        .order('requested_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
