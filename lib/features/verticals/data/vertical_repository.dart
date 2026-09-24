import 'package:supabase_flutter/supabase_flutter.dart';

enum VerticalModule {
  rides,
  rentals,
  realEstate,
  accommodations,
  events,
  jobs,
  professionals,
  agriculture,
  freight,
  health,
  beauty,
  homeServices,
  digital,
  training,
  creative,
  parcels,
}

class VerticalConfig {
  const VerticalConfig({
    required this.table,
    required this.title,
    required this.icon,
    required this.select,
    this.ownOnly = false,
    this.ownerColumn = 'customer_id',
  });

  final String table;
  final String title;
  final int icon;
  final String select;
  final bool ownOnly;
  final String ownerColumn;
}

class VerticalRepository {
  const VerticalRepository(this.client);

  final SupabaseClient client;

  static const configs = <VerticalModule, VerticalConfig>{
    VerticalModule.rides: VerticalConfig(
      table: 'ride_requests',
      title: 'Taxi / Moto / Déplacements',
      icon: 0,
      select: 'id,pickup,destination,status,fare_estimate,created_at',
      ownOnly: true,
    ),
    VerticalModule.rentals: VerticalConfig(
      table: 'vehicle_rentals',
      title: 'Location de véhicules',
      icon: 1,
      select: 'id,vehicle_type,brand,model,daily_price,deposit_amount,active,verification_status',
    ),
    VerticalModule.realEstate: VerticalConfig(
      table: 'real_estate_listings',
      title: 'Immobilier',
      icon: 2,
      select: 'id,listing_type,title,description,price,city,address,latitude,longitude,bedrooms,bathrooms,area_m2',
    ),
    VerticalModule.accommodations: VerticalConfig(
      table: 'accommodations',
      title: 'Hôtels & Hébergements',
      icon: 3,
      select: 'id,name,accommodation_type,description,address,latitude,longitude,accommodation_units(id,name,capacity,price_per_night,quantity,active)',
    ),
    VerticalModule.events: VerticalConfig(
      table: 'events',
      title: 'Événements & Billets',
      icon: 4,
      select: 'id,title,description,venue,starts_at,ends_at,capacity,ticket_price,active',
    ),
    VerticalModule.jobs: VerticalConfig(
      table: 'jobs',
      title: 'Emplois',
      icon: 5,
      select: 'id,title,description,location,active,created_at',
    ),
    VerticalModule.professionals: VerticalConfig(
      table: 'professional_profiles',
      title: 'Professionnels',
      icon: 6,
      select: 'id,profession,experience_years,service_area,bio,hourly_rate,active',
    ),
    VerticalModule.agriculture: VerticalConfig(
      table: 'agriculture_listings',
      title: 'Agriculture',
      icon: 7,
      select: 'id,listing_type,name,description,price,unit,quantity,active,created_at',
    ),
    VerticalModule.freight: VerticalConfig(
      table: 'freight_requests',
      title: 'Fret & Marchandises',
      icon: 8,
      select: 'id,pickup,delivery,weight_kg,volume_m3,description,status,created_at',
      ownOnly: true,
    ),
    VerticalModule.health: VerticalConfig(
      table: 'health_products',
      title: 'Santé',
      icon: 9,
      select: 'id,name,description,price,requires_prescription,stock_quantity,active',
    ),
    VerticalModule.beauty: VerticalConfig(
      table: 'beauty_services',
      title: 'Beauté & Coiffure',
      icon: 10,
      select: 'id,name,description,duration_minutes,price,active',
    ),
    VerticalModule.homeServices: VerticalConfig(
      table: 'home_services',
      title: 'Services à domicile',
      icon: 11,
      select: 'id,service_type,name,description,starting_price,active',
    ),
    VerticalModule.digital: VerticalConfig(
      table: 'digital_services',
      title: 'Services numériques',
      icon: 12,
      select: 'id,category,name,description,price,active',
    ),
    VerticalModule.training: VerticalConfig(
      table: 'training_courses',
      title: 'Formations',
      icon: 13,
      select: 'id,title,description,price,active',
    ),
    VerticalModule.creative: VerticalConfig(
      table: 'creative_services',
      title: 'Créatifs',
      icon: 14,
      select: 'id,category,name,description,starting_price,active',
    ),
    VerticalModule.parcels: VerticalConfig(
      table: 'parcels',
      title: 'Colis & Points relais',
      icon: 15,
      select: 'id,recipient_name,recipient_phone,pickup_address,delivery_address,weight_kg,status,tracking_code,created_at',
      ownOnly: true,
      ownerColumn: 'sender_id',
    ),
  };

  Future<List<Map<String, dynamic>>> list(VerticalModule module) async {
    final config = configs[module]!;
    if (config.ownOnly) {
      final user = client.auth.currentUser;
      if (user == null) return const [];
      final rows = await client
          .from(config.table)
          .select(config.select)
          .eq(config.ownerColumn, user.id)
          .order('created_at', ascending: false)
          .limit(100);
      return _maps(rows);
    }

    final rows = await client
        .from(config.table)
        .select(config.select)
        .limit(100);
    return _maps(rows);
  }

  Future<String> createRide({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
  }) async =>
      (await client.rpc(
        'create_ride_request',
        params: {'p_pickup': pickup, 'p_destination': destination},
      ))
          .toString();

  Future<String> reserveEvent({
    required String eventId,
    required int quantity,
  }) async =>
      (await client.rpc(
        'reserve_event_ticket',
        params: {'p_event_id': eventId, 'p_quantity': quantity},
      ))
          .toString();

  Future<String> bookRental({
    required String rentalId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async =>
      (await client.rpc(
        'create_vehicle_rental_booking',
        params: {
          'p_rental_id': rentalId,
          'p_starts_at': startsAt.toUtc().toIso8601String(),
          'p_ends_at': endsAt.toUtc().toIso8601String(),
        },
      ))
          .toString();

  Future<String> bookAccommodation({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async =>
      (await client.rpc(
        'create_accommodation_booking',
        params: {
          'p_unit_id': unitId,
          'p_check_in': _date(checkIn),
          'p_check_out': _date(checkOut),
          'p_guests': guests,
        },
      ))
          .toString();

  Future<String> enrollTraining(String courseId) async =>
      (await client.rpc(
        'enroll_training_course',
        params: {'p_course_id': courseId},
      ))
          .toString();

  Future<String> orderDigital(String serviceId) async =>
      (await client.rpc(
        'create_digital_order',
        params: {'p_service_id': serviceId},
      ))
          .toString();

  Future<String> bookBeauty({
    required String serviceId,
    required DateTime scheduledAt,
  }) async =>
      (await client.rpc(
        'create_beauty_booking',
        params: {
          'p_service_id': serviceId,
          'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
        },
      ))
          .toString();

  Future<String> requestHomeService({
    required String serviceId,
    required DateTime scheduledAt,
    required Map<String, dynamic> address,
  }) async =>
      (await client.rpc(
        'create_home_service_request',
        params: {
          'p_service_id': serviceId,
          'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'p_address': address,
        },
      ))
          .toString();

  Future<String> applyToJob(String jobId) async =>
      (await client.rpc(
        'apply_to_job',
        params: {'p_job_id': jobId},
      ))
          .toString();

  String _date(DateTime value) => value.toIso8601String().substring(0, 10);

  List<Map<String, dynamic>> _maps(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
