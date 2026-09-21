import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryTrackingRepository {
 const DeliveryTrackingRepository(this.client);
 final SupabaseClient client;

 Future<List<Map<String,dynamic>>> recentLocations(String courierId) async {
  final rows=await client.from('courier_locations').select('courier_id,location,accuracy_m,recorded_at').eq('courier_id',courierId).order('recorded_at',ascending:false).limit(50);
  return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 }
}