import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicRepository {
  const MechanicRepository(this.client);

  final SupabaseClient client;

  Future<String> createRequest({
    required String vehicleType,
    required String problemType,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final result = await client.rpc(
      'create_mechanic_request',
      params: {
        'p_vehicle_type': vehicleType,
        'p_problem_type': problemType,
        'p_description': description,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );
    return result as String;
  }

  Future<List<Map<String, dynamic>>> activeMechanics({
    int limit = 50,
  }) async {
    final rows = await client
        .from('mechanics')
        .select(
          'id,display_name,phone,verification_status,active,service_radius_km',
        )
        .eq('active', true)
        .limit(limit);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
