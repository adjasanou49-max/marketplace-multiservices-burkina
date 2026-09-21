import 'package:supabase_flutter/supabase_flutter.dart';
class AdminProductRepository {
 const AdminProductRepository(this.client); final SupabaseClient client;
 Future<List<Map<String,dynamic>>> pending() async {
  final rows=await client.from('products').select('id,name,price,shop_id,status,created_at').order('created_at',ascending:false).limit(200);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
 Future<void> setStatus(String productId,String status,String reason) async {
  await client.rpc('admin_set_product_status',params:{'p_product_id':productId,'p_status':status,'p_reason':reason});
 }
}