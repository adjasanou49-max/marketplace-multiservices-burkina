import 'package:supabase_flutter/supabase_flutter.dart';
class PaymentHistoryRepository {
 const PaymentHistoryRepository(this.client); final SupabaseClient client;
 Future<List<Map<String,dynamic>>> mine() async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final rows=await client.from('payments').select('id,order_id,provider,provider_reference,amount,currency,status,created_at').eq('order_id',u.id).order('created_at',ascending:false).limit(100);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
}