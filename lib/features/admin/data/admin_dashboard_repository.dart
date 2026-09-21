import 'package:supabase_flutter/supabase_flutter.dart';
class AdminDashboardRepository {
 const AdminDashboardRepository(this.client); final SupabaseClient client;
 Future<Map<String,int>> counts() async {
  Future<int> count(String table) async { final x=await client.from(table).select('id').count(CountOption.exact); return x.count; }
  return {'users':await count('profiles'),'sellers':await count('sellers'),'shops':await count('shops'),'orders':await count('orders'),'products':await count('products'),'couriers':await count('delivery_drivers')};
 }
}