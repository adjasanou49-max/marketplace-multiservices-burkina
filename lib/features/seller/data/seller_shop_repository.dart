import 'package:supabase_flutter/supabase_flutter.dart';

class SellerShopRepository {
  const SellerShopRepository(this.client);

  final SupabaseClient client;

  Future<Map<String, dynamic>?> mine() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final seller = await client
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (seller == null) return null;

    final rows = await client
        .from('shops')
        .select()
        .eq('seller_id', seller['id'])
        .order('created_at', ascending: false)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<String> createShop({
    required String name,
    String? description,
    String? phone,
    String? address,
    String? logoUrl,
    String? coverUrl,
  }) async {
    final result = await client.rpc(
      'create_seller_shop',
      params: {
        'p_name': name.trim(),
        'p_description': description?.trim(),
        'p_phone': phone?.trim(),
        'p_address': address?.trim(),
        'p_logo_url': logoUrl?.trim(),
        'p_cover_url': coverUrl?.trim(),
      },
    );
    return result as String;
  }
}