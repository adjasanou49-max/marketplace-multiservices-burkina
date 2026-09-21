import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryRepository {
  const DeliveryRepository(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> packagesForOrder(
    String orderId,
  ) async {
    final groups = await client
        .from('order_groups')
        .select(
          'id,shop_id,shops(name),order_packages(id,status,picked_up_at,delivered_at,updated_at,delivery_assignments(id,courier_id,status,accepted_at,completed_at))',
        )
        .eq('order_id', orderId)
        .order('created_at');

    final result = <Map<String, dynamic>>[];

    for (final rawGroup in groups as List) {
      final group = Map<String, dynamic>.from(rawGroup as Map);
      final rawPackages = group['order_packages'];
      final packages = rawPackages is List ? rawPackages : const [];

      for (final rawPackage in packages) {
        final package = Map<String, dynamic>.from(rawPackage as Map);
        package['shop_name'] = group['shops'] is Map
            ? (group['shops'] as Map)['name']
            : null;

        final assignments = package['delivery_assignments'];
        final assignment = assignments is List && assignments.isNotEmpty
            ? Map<String, dynamic>.from(assignments.first as Map)
            : null;
        package['assignment'] = assignment;

        if (assignment != null) {
          final courierId = assignment['courier_id']?.toString();

          if (courierId != null && courierId.isNotEmpty) {
            final locations = await client
                .from('courier_locations')
                .select('id,location,accuracy_m,recorded_at')
                .eq('courier_id', courierId)
                .order('recorded_at', ascending: false)
                .limit(1);

            if ((locations as List).isNotEmpty) {
              package['latest_location'] =
                  Map<String, dynamic>.from(locations.first as Map);
            }
          }
        }

        result.add(package);
      }
    }

    return result;
  }

  RealtimeChannel watchOrder(
    String orderId,
    VoidCallback onChange,
  ) {
    return client
        .channel('delivery-order-$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'courier_locations',
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_events',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
