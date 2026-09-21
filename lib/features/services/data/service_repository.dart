import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRepository {
  const ServiceRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> categories() async {
    final rows = await client
        .from('service_categories')
        .select('id,name,slug,icon_url,sort_order')
        .eq('active', true)
        .order('sort_order')
        .limit(100);

    return _maps(rows);
  }

  Future<List<Map<String, dynamic>>> services({
    String? category,
    int limit = 100,
  }) async {
    if (limit <= 0 || limit > 100) {
      throw ArgumentError('Limite invalide.');
    }

    var query = client
        .from('services')
        .select(
          'id,provider_id,category,name,description,price,active,created_at,'
          'service_providers!inner(display_name,verification_status,active)',
        )
        .eq('active', true)
        .eq('service_providers.active', true);

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return _maps(rows);
  }

  Future<String> createRequest({
    required String serviceId,
    DateTime? scheduledAt,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    final result = await client.rpc(
      'create_service_request',
      params: {
        'p_service_id': serviceId,
        'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_description': description,
      },
    );

    return result.toString();
  }

  List<Map<String, dynamic>> _maps(dynamic rows) {
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
