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
          'id,display_name,verification_status,active,service_radius_km',
        )
        .eq('active', true)
        .eq('verification_status', 'VERIFIED')
        .order('display_name')
        .limit(limit);

    final mechanics = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    if (mechanics.isEmpty) return mechanics;

    final ids = mechanics
        .map((mechanic) => mechanic['id']?.toString())
        .whereType<String>()
        .toList();
    final availabilityRows = await client
        .from('mechanic_availability')
        .select('mechanic_id,status,starts_at,ends_at')
        .inFilter('mechanic_id', ids)
        .order('starts_at', ascending: false);

    final now = DateTime.now().toUtc();
    final byMechanic = <String, Map<String, dynamic>>{};
    for (final raw in (availabilityRows as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final mechanicId = row['mechanic_id']?.toString();
      final startsAt = DateTime.tryParse(row['starts_at']?.toString() ?? '');
      final endsAt = row['ends_at'] == null
          ? null
          : DateTime.tryParse(row['ends_at'].toString());
      if (mechanicId == null || startsAt == null) continue;
      final activeNow = !now.isBefore(startsAt) &&
          (endsAt == null || now.isBefore(endsAt));
      if (activeNow && !byMechanic.containsKey(mechanicId)) {
        byMechanic[mechanicId] = row;
      }
    }

    for (final mechanic in mechanics) {
      final status = byMechanic[mechanic['id']?.toString()];
      mechanic['availability_status'] =
          status?['status']?.toString() ?? 'UNAVAILABLE';
    }

    return mechanics;
  }

  Future<Map<String, dynamic>?> defaultCustomerAddress() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('delivery_addresses')
        .select('id,recipient_name,address_line,city,latitude,longitude')
        .eq('customer_id', user.id)
        .eq('is_default', true)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<String> createRequest({
    required String vehicleType,
    required String problemType,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    final result = await client.rpc(
      'create_mechanic_request',
      params: {
        'p_vehicle_type': vehicleType,
        'p_problem_type': problemType,
        'p_description': description.trim().isEmpty ? null : description.trim(),
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );
    return result as String;
  }
}