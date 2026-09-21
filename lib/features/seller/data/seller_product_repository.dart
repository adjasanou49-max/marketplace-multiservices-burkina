import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProductRepository {
  const SellerProductRepository(this.client);
  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> products(String shopId) async {
    final rows = await client.from('products').select('id,name,price,status,shop_id,inventory(quantity,reserved_quantity)').eq('shop_id', shopId).order('created_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> updateActive(String productId, bool active) async {
    await client.from('products').update({'status': active ? 'ACTIVE' : 'INACTIVE'}).eq('id', productId);
  }
}