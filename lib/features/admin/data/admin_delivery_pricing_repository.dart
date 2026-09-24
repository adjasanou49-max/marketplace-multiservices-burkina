import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryPricingRule {
  const DeliveryPricingRule({
    required this.id,
    required this.name,
    required this.minDistanceKm,
    this.maxDistanceKm,
    required this.baseFee,
    required this.perKmFee,
    required this.perStopFee,
    required this.active,
  });

  final String id;
  final String name;
  final num minDistanceKm;
  final num? maxDistanceKm;
  final num baseFee;
  final num perKmFee;
  final num perStopFee;
  final bool active;

  factory DeliveryPricingRule.fromMap(Map<String, dynamic> row) {
    return DeliveryPricingRule(
      id: row['id'].toString(),
      name: row['name']?.toString() ?? 'Tarif',
      minDistanceKm: row['min_distance_km'] as num? ?? 0,
      maxDistanceKm: row['max_distance_km'] as num?,
      baseFee: row['base_fee'] as num? ?? 0,
      perKmFee: row['per_km_fee'] as num? ?? 0,
      perStopFee: row['per_stop_fee'] as num? ?? 0,
      active: row['active'] == true,
    );
  }
}

class AdminDeliveryPricingRepository {
  const AdminDeliveryPricingRepository(this.client);

  final SupabaseClient client;

  Future<List<DeliveryPricingRule>> all() async {
    final rows = await client
        .from('delivery_pricing_rules')
        .select()
        .order('min_distance_km');
    return (rows as List)
        .map((row) =>
            DeliveryPricingRule.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> updateRule({
    required String id,
    required String name,
    required num baseFee,
    required num perKmFee,
    required num perStopFee,
    required bool active,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Le nom du tarif est obligatoire.');
    }
    if (baseFee < 0 || perKmFee < 0 || perStopFee < 0) {
      throw ArgumentError('Les frais de livraison ne peuvent pas être négatifs.');
    }

    await client.from('delivery_pricing_rules').update({
      'name': normalizedName,
      'base_fee': baseFee,
      'per_km_fee': perKmFee,
      'per_stop_fee': perStopFee,
      'active': active,
    }).eq('id', id);
  }
}