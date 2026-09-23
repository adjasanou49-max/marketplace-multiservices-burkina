import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryTrackingRepository {
  const DeliveryTrackingRepository(this.client);

  final SupabaseClient client;

  Future<List<String>> _orderPackageIds(String orderId, String userId) async {
    final order = await client
        .from('orders')
        .select('id')
        .eq('id', orderId)
        .eq('customer_id', userId)
        .maybeSingle();

    if (order == null) {
      throw StateError('Commande inaccessible');
    }

    final groups = await client
        .from('order_groups')
        .select('id')
        .eq('order_id', orderId);

    final groupIds = (groups as List)
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (groupIds.isEmpty) return const [];

    final packages = await client
        .from('order_packages')
        .select('id')
        .inFilter('order_group_id', groupIds);

    return (packages as List)
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> _assertCourierAssignedToOrder({
    required String orderId,
    required String courierId,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final packageIds = await _orderPackageIds(orderId, user.id);
    if (packageIds.isEmpty) {
      throw StateError('Aucun colis de livraison pour cette commande');
    }

    final assignment = await client
        .from('delivery_assignments')
        .select('id')
        .eq('courier_id', courierId)
        .inFilter('package_id', packageIds)
        .limit(1)
        .maybeSingle();

    if (assignment == null) {
      throw StateError('Livreur non affecté à cette commande');
    }
  }

  Future<List<Map<String, dynamic>>> recentLocations({
    required String orderId,
    required String courierId,
  }) async {
    await _assertCourierAssignedToOrder(
      orderId: orderId,
      courierId: courierId,
    );

    final rows = await client
        .from('courier_locations')
        .select('courier_id,location,accuracy_m,recorded_at')
        .eq('courier_id', courierId)
        .order('recorded_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<RealtimeChannel> subscribe({
    required String orderId,
    required String courierId,
    required void Function(Map<String, dynamic>) onLocation,
  }) async {
    await _assertCourierAssignedToOrder(
      orderId: orderId,
      courierId: courierId,
    );

    final channel = client.channel('courier-location:$orderId:$courierId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'courier_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'courier_id',
            value: courierId,
          ),
          callback: (payload) => onLocation(
            Map<String, dynamic>.from(payload.newRecord),
          ),
        )
        .subscribe();

    return channel;
  }
}
