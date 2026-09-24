import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRecord {
  const BookingRecord({
    required this.kind,
    required this.id,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.amount,
    this.reference,
  });

  final String kind;
  final String id;
  final String status;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final num? amount;
  final String? reference;
}

class BookingsRepository {
  const BookingsRepository(this.client);

  final SupabaseClient client;

  Future<List<BookingRecord>> currentUserRecords() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const [];

    final results = await Future.wait<List<BookingRecord>>([
      _query(table: 'transport_bookings', userColumn: 'customer_id', userId: userId, kind: 'Transport', fields: 'id,status,total_amount,created_at'),
      _query(table: 'event_bookings', userColumn: 'customer_id', userId: userId, kind: 'Événement', fields: 'id,status,total_amount,created_at'),
      _query(table: 'vehicle_rental_bookings', userColumn: 'customer_id', userId: userId, kind: 'Location de véhicule', fields: 'id,status,total_amount,starts_at,created_at'),
      _query(table: 'accommodation_bookings', userColumn: 'customer_id', userId: userId, kind: 'Hébergement', fields: 'id,status,total_amount,check_in,created_at'),
      _query(
        table: 'beauty_bookings',
        userColumn: 'customer_id',
        userId: userId,
        kind: 'Beauté',
        fields: 'id,status,amount,scheduled_at',
        orderColumn: 'scheduled_at',
      ),
      _query(table: 'service_bookings', userColumn: 'customer_id', userId: userId, kind: 'Service', fields: 'id,status,total_amount,scheduled_at,created_at'),
      _query(table: 'training_enrollments', userColumn: 'customer_id', userId: userId, kind: 'Formation', fields: 'id,status,created_at'),
      _query(table: 'digital_orders', userColumn: 'customer_id', userId: userId, kind: 'Service numérique', fields: 'id,status,amount,created_at'),
      _query(table: 'mechanic_requests', userColumn: 'customer_id', userId: userId, kind: 'Mécanicien', fields: 'id,status,created_at'),
      _query(table: 'ride_requests', userColumn: 'customer_id', userId: userId, kind: 'Trajet', fields: 'id,status,fare_estimate,created_at'),
      _query(table: 'freight_requests', userColumn: 'customer_id', userId: userId, kind: 'Fret', fields: 'id,status,created_at'),
      _query(table: 'parcels', userColumn: 'sender_id', userId: userId, kind: 'Colis', fields: 'id,status,tracking_code,created_at'),
    ]);

    final records = results.expand((items) => items).toList();
    records.sort((a, b) {
      final aDate = a.scheduledAt ?? a.createdAt;
      final bDate = b.scheduledAt ?? b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return records;
  }

  Future<List<BookingRecord>> _query({
    required String table,
    required String userColumn,
    required String userId,
    required String kind,
    required String fields,
    String orderColumn = 'created_at',
  }) async {
    try {
      final rows = await client.from(table).select(fields).eq(userColumn, userId).order(orderColumn, ascending: false).limit(100);
      return (rows as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        return BookingRecord(
          kind: kind,
          id: row['id']?.toString() ?? '',
          status: row['status']?.toString() ?? 'UNKNOWN',
          createdAt: _dateTime(row['created_at']),
          scheduledAt: _dateTime(row['scheduled_at'] ?? row['starts_at'] ?? row['check_in']),
          amount: _number(row['total_amount'] ?? row['amount'] ?? row['fare_estimate']),
          reference: row['tracking_code']?.toString(),
        );
      }).where((record) => record.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  DateTime? _dateTime(dynamic value) => DateTime.tryParse(value?.toString() ?? '');

  num? _number(dynamic value) => value is num ? value : num.tryParse(value?.toString() ?? '');
}
