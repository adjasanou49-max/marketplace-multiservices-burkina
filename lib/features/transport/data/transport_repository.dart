import 'package:supabase_flutter/supabase_flutter.dart';

class TransportRepository {
  const TransportRepository(this.client);

  final SupabaseClient client;

  Future<String> bookTrip({
    required String tripId,
    required int quantity,
    required String passengerName,
  }) async {
    final result = await client.rpc(
      'create_transport_booking_secure',
      params: {
        'p_trip_id': tripId,
        'p_quantity': quantity,
        'p_passenger': {'name': passengerName},
      },
    );
    return result as String;
  }

  Future<List<Map<String, dynamic>>> upcomingTrips({
    int limit = 50,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await client
        .from('transport_trips')
        .select(
          'id,route_id,vehicle_id,departure_at,arrival_at,price,status',
        )
        .gte('departure_at', now)
        .order('departure_at')
        .limit(limit);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
