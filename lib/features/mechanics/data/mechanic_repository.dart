import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicRepository {
  const MechanicRepository(this.client);

  final SupabaseClient client;

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
