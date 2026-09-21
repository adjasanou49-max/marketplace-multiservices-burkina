import 'package:supabase_flutter/supabase_flutter.dart';
class AdminDashboardRepository {
 const AdminDashboardRepository(this.client); final SupabaseClient client;
 Future<Map<String,int>> counts() async {
  final raw=await client.rpc('get_admin_dashboard');
  final m=Map<String,dynamic>.from(raw as Map);
  return m.map((k,v)=>MapEntry(k,(v as num).toInt()));
 }
}