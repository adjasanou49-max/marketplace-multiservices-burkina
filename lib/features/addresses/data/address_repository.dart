import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/delivery_address.dart';

class AddressRepository {
  const AddressRepository(this.client);
  final SupabaseClient client;

  Future<List<DeliveryAddress>> listMine() async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');
    final rows = await client.from('delivery_addresses').select().eq('customer_id', user.id).order('is_default', ascending: false).order('created_at', ascending: false);
    return (rows as List).map((r) => DeliveryAddress.fromMap(Map<String, dynamic>.from(r as Map))).toList();
  }

  Future<String> create({
    required String recipientName,
    String? label,
    String? phone,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Utilisateur non authentifié');
    final row = await client.from('delivery_addresses').insert({
      'customer_id': user.id,
      'recipient_name': recipientName,
      'label': label,
      'phone': phone,
      'address_line': addressLine,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    }).select('id').single();
    return row['id'] as String;
  }
}
