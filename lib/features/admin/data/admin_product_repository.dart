import 'package:supabase_flutter/supabase_flutter.dart';
class AdminProductRepository {
 const AdminProductRepository(this.client); final SupabaseClient client;
 Future<List<Map<String,dynamic>>> pending() async {
  final rows=await client.from('products').select('id,name,price,stock,shop_id,is_active,created_at').order('created_at',ascending:false).limit(200);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
 Future<void> setActive(String productId,bool active) async {
  await client.from('products').update({'is_active':active}).eq('id',productId);
 }
}