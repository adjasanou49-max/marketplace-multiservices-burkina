import 'package:supabase_flutter/supabase_flutter.dart';

class SellerOrderRepository {
 const SellerOrderRepository(this.client); final SupabaseClient client;

 Future<List<Map<String,dynamic>>> mine() async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final seller=await client.from('sellers').select('id').eq('user_id',u.id).single();
  final shops=await client.from('shops').select('id').eq('seller_id',seller['id']);
  final ids=(shops as List).map((e)=>(e as Map)['id']).toList();
  if(ids.isEmpty)return const [];
  final rows=await client.from('order_groups').select('id,order_id,shop_id,status,subtotal,created_at,orders!inner(customer_id,total,currency,created_at)').inFilter('shop_id',ids).order('created_at',ascending:false);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
 Future<Map<String,dynamic>> detail(String groupId) async {
  final group=await client.from('order_groups').select('*,orders!inner(*)').eq('id',groupId).single();
  final items=await client.from('order_items').select().eq('order_group_id',groupId);
  return {'group':Map<String,dynamic>.from(group),'items':(items as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList()};
 }
}