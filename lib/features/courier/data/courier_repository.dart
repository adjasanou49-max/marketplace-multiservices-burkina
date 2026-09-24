import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/delivery_assignment.dart';

class CourierRepository {
  const CourierRepository(this.client);
  final SupabaseClient client;

  Future<List<DeliveryAssignment>> assignments() async {
    final u=client.auth.currentUser;
    if(u==null) throw StateError('Utilisateur non authentifié');
    final rows=await client.from('delivery_assignments').select().eq('courier_id',u.id).order('assigned_at',ascending:false);
    return (rows as List).map((e)=>DeliveryAssignment.fromMap(Map<String,dynamic>.from(e as Map))).toList();
  }

  Future<List<Map<String,dynamic>>> activeLocations(String courierId) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }
    if (courierId != user.id) {
      throw StateError('Accès aux positions du livreur refusé');
    }

    final rows = await client
        .from('courier_locations')
        .select('id,location,accuracy_m,recorded_at')
        .eq('courier_id', user.id)
        .order('recorded_at', ascending: false)
        .limit(20);

    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}