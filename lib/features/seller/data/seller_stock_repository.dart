import 'package:supabase_flutter/supabase_flutter.dart';

class SellerStockRepository {
 const SellerStockRepository(this.client);
 final SupabaseClient client;

 Future<List<Map<String,dynamic>>> stock(String shopId) async {
  final rows=await client.from('inventory').select('product_id,quantity,reserved_quantity,updated_at,products!inner(name,shop_id)').eq('products.shop_id',shopId).order('updated_at',ascending:false);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
}