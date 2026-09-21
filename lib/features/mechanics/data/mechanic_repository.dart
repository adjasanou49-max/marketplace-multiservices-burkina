import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicRepository {
  const MechanicRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> mechanics() async {
    final rows = await client
        .from('mechanics')
        .select(
          'id,display_name,phone,verification_status,active,service_radius_km,mechanic_services(service_type,vehicle_type,base_price),mechanic_availability(status,starts_at,ends_at)',
        )
        .eq('active', true)
        .eq('verification_status', 'VERIFIED')
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<String> createRequest({
    required String vehicleType,
    required String problemType,
    String? description,
    required double latitude,
    required double longitude,
  }) async {
    final raw = await client.rpc(
      'create_mechanic_request',
      params: {
        'p_vehicle_type': vehicleType,
        'p_problem_type': problemType,
        'p_description': description,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );

    return raw.toString();
  }

  Future<List<Map<String, dynamic>>> myQuotes() async {
    final rows = await client
        .from('mechanic_quotes')
        .select(
          'id,request_id,mechanic_id,amount,currency,diagnosis,status,expires_at,created_at,mechanics(display_name,phone)',
        )
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<String> acceptQuote(String quoteId) async {
    final raw = await client.rpc(
      'accept_mechanic_quote',
      params: {'p_quote_id': quoteId},
    );
    return raw.toString();
  }
}
