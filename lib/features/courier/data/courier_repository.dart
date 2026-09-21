import 'package:supabase_flutter/supabase_flutter.dart';

class CourierRepository {
  const CourierRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> assignments() async {
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .from('delivery_assignments')
        .select(
          'id,package_id,courier_id,status,assigned_at,accepted_at,completed_at',
        )
        .eq('courier_id', user.id)
        .order('assigned_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> accept(String assignmentId) async {
    await client.rpc(
      'accept_delivery_assignment',
      params: {'p_assignment_id': assignmentId},
    );
  }

  Future<void> start(String packageId) async {
    await client.rpc(
      'start_package_delivery',
      params: {'p_package_id': packageId},
    );
  }

  Future<void> recordLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await client.rpc(
      'record_courier_location',
      params: {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_accuracy_m': accuracy,
      },
    );
  }
}
