import 'package:supabase_flutter/supabase_flutter.dart';

class TransportRepository {
  const TransportRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> upcomingTrips({
    int limit = 50,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await client
        .from('transport_trips')
        .select('id,route_id,vehicle_id,departure_at,arrival_at,price,status')
        .eq('status', 'SCHEDULED')
        .gte('departure_at', now)
        .order('departure_at')
        .limit(limit);

    final trips = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (trips.isEmpty) return trips;

    final routeIds = trips
        .map((trip) => trip['route_id']?.toString())
        .whereType<String>()
        .toList();
    final routeRows = await client
        .from('transport_routes')
        .select(
          'id,company_id,departure_station_id,arrival_station_id,duration_minutes,base_price',
        )
        .inFilter('id', routeIds);
    final routes = <String, Map<String, dynamic>>{};
    for (final raw in (routeRows as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      routes[row['id'].toString()] = row;
    }

    final companyIds = routes.values
        .map((route) => route['company_id']?.toString())
        .whereType<String>()
        .toList();
    final stationIds = routes.values
        .expand((route) => [
          route['departure_station_id']?.toString(),
          route['arrival_station_id']?.toString(),
        ])
        .whereType<String>()
        .toSet()
        .toList();

    final companyRows = companyIds.isEmpty
        ? const []
        : await client
            .from('transport_companies')
            .select('id,name,phone,verification_status,active')
            .inFilter('id', companyIds);
    final stationRows = stationIds.isEmpty
        ? const []
        : await client
            .from('transport_stations')
            .select('id,name,address,latitude,longitude')
            .inFilter('id', stationIds);

    final companies = <String, Map<String, dynamic>>{};
    for (final raw in companyRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      companies[row['id'].toString()] = row;
    }
    final stations = <String, Map<String, dynamic>>{};
    for (final raw in stationRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      stations[row['id'].toString()] = row;
    }

    for (final trip in trips) {
      final route = routes[trip['route_id']?.toString()];
      if (route == null) continue;
      trip['route'] = route;
      trip['company'] = companies[route['company_id']?.toString()];
      trip['departure_station'] =
          stations[route['departure_station_id']?.toString()];
      trip['arrival_station'] =
          stations[route['arrival_station_id']?.toString()];
    }

    return trips;
  }

  Future<String> createBooking({
    required String tripId,
    required int quantity,
    required String passengerName,
  }) async {
    if (quantity <= 0) throw ArgumentError('Quantité invalide.');
    final result = await client.rpc(
      'create_transport_booking_secure',
      params: {
        'p_trip_id': tripId,
        'p_quantity': quantity,
        'p_passenger': {'name': passengerName.trim()},
      },
    );
    return result as String;
  }
}