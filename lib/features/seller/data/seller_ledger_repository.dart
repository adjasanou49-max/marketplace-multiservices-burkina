import 'package:supabase_flutter/supabase_flutter.dart';

class SellerLedgerRepository {
 const SellerLedgerRepository(this.client);
 final SupabaseClient client;

 Future<List<Map<String,dynamic>>> mine() async {
  final s=client.auth.currentUser; if(s==null)throw StateError('Utilisateur non authentifié');
  final seller=await client.from('sellers').select('id').eq('user_id',s.id).single();
  final rows=await client.from('seller_ledger').select().eq('seller_id',seller['id']).order('created_at',ascending:false).limit(100);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
}