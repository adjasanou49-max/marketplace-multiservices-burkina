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
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> services({String? category, int limit = 100}) async {
    var query = client
        .from('services')
        .select('id,provider_id,category,name,description,price,active,created_at,service_providers!inner(display_name,verification_status,active)')
        .eq('active', true)
        .eq('service_providers.active', true);
    if (category != null && category.isNotEmpty) query = query.eq('category', category);
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<String> createRequest({required String serviceId, String? description}) async {
    final result = await client.rpc('create_service_request', params: {
      'p_service_id': serviceId,
      'p_description': description,
    });
    return result as String;
  }
}
