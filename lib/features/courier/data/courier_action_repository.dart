import 'package:supabase_flutter/supabase_flutter.dart';
class CourierActionRepository {
 const CourierActionRepository(this.client); final SupabaseClient client;
 Future<List<Map<String,dynamic>>> packages() async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final rows=await client.from('delivery_assignments').select('id,package_id,courier_id,status,assigned_at,order_packages(id,status,picked_up_at,delivered_at)').eq('courier_id',u.id).order('assigned_at',ascending:false).limit(100);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
 Future<void> accept(String id) async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  await client.from('delivery_assignments').update({'status':'ACCEPTED','accepted_at':DateTime.now().toUtc().toIso8601String()}).eq('id',id).eq('courier_id',u.id);
 }
}