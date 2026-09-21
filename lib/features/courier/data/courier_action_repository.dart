import 'package:supabase_flutter/supabase_flutter.dart';

class CourierActionRepository {
 const CourierActionRepository(this.client); final SupabaseClient client;
 Future<List<Map<String,dynamic>>> packages() async {
  final u=client.auth.currentUser;if(u==null)throw StateError('Utilisateur non authentifié');
  final rows=await client.from('delivery_assignments').select('id,package_id,courier_id,status,assigned_at,accepted_at,order_packages(id,status,picked_up_at,delivered_at)').eq('courier_id',u.id).order('assigned_at',ascending:false).limit(100);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
 Future<void> accept(String assignmentId) async { await client.rpc('accept_delivery_assignment',params:{'p_assignment_id':assignmentId}); }
 Future<void> pickup(String packageId,String code) async { await client.rpc('confirm_package_pickup',params:{'p_package_id':packageId,'p_pickup_code':code}); }
 Future<void> startDelivery(String packageId) async { await client.rpc('start_package_delivery',params:{'p_package_id':packageId}); }
 Future<void> deliver(String packageId,String code) async { await client.rpc('confirm_package_delivery',params:{'p_package_id':packageId,'p_delivery_code':code}); }
}