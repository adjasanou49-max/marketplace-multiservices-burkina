import 'package:supabase_flutter/supabase_flutter.dart';

class TransportRepository {
  const TransportRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> upcoming() async {
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = await client
        .from('transport_trips')
        .select(
          'id,departure_at,arrival_at,price,status,transport_routes(id,base_price,duration_minutes,transport_companies(id,name,phone),departure:transport_stations!transport_routes_departure_station_id_fkey(id,name,address),arrival:transport_stations!transport_routes_arrival_station_id_fkey(id,name,address))',
        )
        .gte('departure_at', now)
        .inFilter('status', ['SCHEDULED', 'BOARDING'])
        .order('departure_at')
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<String> reserve({
    required String tripId,
    required String passengerName,
  }) async {
    final raw = await client.rpc(
      'create_transport_booking_secure',
      params: {
        'p_trip_id': tripId,
        'p_quantity': 1,
        'p_passenger': {'name': passengerName},
      },
    );

    return raw.toString();
  }

  Future<List<Map<String, dynamic>>> myBookings() async {
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .from('transport_bookings')
        .select(
          'id,trip_id,quantity,total_amount,status,created_at,transport_trips(departure_at,arrival_at,transport_routes(transport_companies(name),departure:transport_stations!transport_routes_departure_station_id_fkey(name),arrival:transport_stations!transport_routes_arrival_station_id_fkey(name)))',
        )
        .eq('customer_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> myTickets() async {
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .from('transport_tickets')
        .select(
          'id,booking_id,passenger_name,seat_number,status,created_at,transport_bookings!inner(customer_id)',
        )
        .eq('transport_bookings.customer_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
