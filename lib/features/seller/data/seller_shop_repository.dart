import 'package:supabase_flutter/supabase_flutter.dart';

class SellerShopRepository {
 const SellerShopRepository(this.client);
 final SupabaseClient client;
 Future<Map<String,dynamic>?> mine() async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final seller=await client.from('sellers').select('id').eq('user_id',u.id).single();
  final rows=await client.from('shops').select().eq('seller_id',seller['id']).limit(1);
  if((rows as List).isEmpty)return null;
  return Map<String,dynamic>.from(rows.first as Map);
 }
}