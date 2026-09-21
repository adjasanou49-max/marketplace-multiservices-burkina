import 'package:supabase_flutter/supabase_flutter.dart';
class SellerPayoutRepository {
 const SellerPayoutRepository(this.client); final SupabaseClient client;
 Future<List<Map<String,dynamic>>> mine() async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final seller=await client.from('sellers').select('id').eq('user_id',u.id).single();
  final rows=await client.from('seller_payouts').select('id,amount,currency,provider,provider_reference,status,requested_at,paid_at').eq('seller_id',seller['id']).order('requested_at',ascending:false).limit(100);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
}