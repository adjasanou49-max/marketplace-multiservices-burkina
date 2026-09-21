import 'package:supabase_flutter/supabase_flutter.dart';
class PaymentHistoryRepository {
 const PaymentHistoryRepository(this.client); final SupabaseClient client;
 Future<List<Map<String,dynamic>>> mine() async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final orders=await client.from('orders').select('id').eq('customer_id',u.id);
  final ids=(orders as List).map((e)=>(e as Map)['id']).toList();if(ids.isEmpty)return const [];
  final rows=await client.from('payments').select('id,order_id,provider,provider_reference,amount,currency,status,created_at').inFilter('order_id',ids).order('created_at',ascending:false).limit(100);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
}