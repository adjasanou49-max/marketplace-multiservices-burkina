import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/delivery_repository.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : DeliveryRepository(client);
});

class DeliveryTrackingPage extends ConsumerStatefulWidget {
  const DeliveryTrackingPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  ConsumerState<DeliveryTrackingPage> createState() =>
      _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState
    extends ConsumerState<DeliveryTrackingPage> {
  late Future<List<Map<String, dynamic>>> _future;
  RealtimeChannel? _channel;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _future = _load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(deliveryRepositoryProvider);
      if (repo != null) {
        _channel = repo.watchOrder(
          widget.orderId,
          () {
            if (!mounted) return;
            setState(() => _future = _load());
          },
        );
      }

      _timer = Timer.periodic(
        const Duration(seconds: 15),
        (_) {
          if (!mounted) return;
          setState(() => _future = _load());
        },
      );
    });
  }

  Future<List<Map<String, dynamic>>> _load() {
    final repo = ref.read(deliveryRepositoryProvider);
    if (repo == null) return Future.value(const []);
    return repo.packagesForOrder(widget.orderId);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_channel != null) {
      ref.read(supabaseProvider)?.removeChannel(_channel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de livraison'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur du suivi : ' + snapshot.error.toString(),
              ),
            );
          }

          final packages =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (packages.isEmpty) {
            return const Center(
              child: Text('Aucun colis de livraison trouvé.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final package = packages[index];
              final assignment = package['assignment'] is Map
                  ? Map<String, dynamic>.from(package['assignment'] as Map)
                  : null;
              final location = package['latest_location'] is Map
                  ? Map<String, dynamic>.from(
                      package['latest_location'] as Map,
                    )
                  : null;
              final point = location == null
                  ? null
                  : _parsePoint(location['location']);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Boutique : ' +
                            (package['shop_name']?.toString() ??
                                'Boutique'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Colis : ' +
                            (package['id']?.toString() ?? '-') +
                            '\nÉtat : ' +
                            (package['status']?.toString() ?? '-'),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _progress(package['status']?.toString()),
                      ),
                      const SizedBox(height: 10),
                      if (assignment != null)
                        Text(
                          'Livreur : ' +
                              (assignment['courier_id']?.toString() ??
                                  '-') +
                              '\nAffectation : ' +
                              (assignment['status']?.toString() ?? '-'),
                        ),
                      if (location != null) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        const Text('Dernière position du livreur'),
                        const SizedBox(height: 4),
                        Text(
                          'Position : ' +
                              (location['location']?.toString() ?? '-') +
                              '\nPrécision : ' +
                              (location['accuracy_m']?.toString() ??
                                  '-') +
                              ' m\nMise à jour : ' +
                              (location['recorded_at']?.toString() ?? '-'),
                        ),
                        if (point != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 220,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: point,
                                  initialZoom: 15,
                                  minZoom: 5,
                                  maxZoom: 19,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'marketplace_multiservices_burkina',
                                    maxZoom: 19,
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: point,
                                        width: 48,
                                        height: 48,
                                        child: const Icon(
                                          Icons.location_on,
                                          size: 44,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SimpleAttributionWidget(
                                    source: const Text(
                                      'OpenStreetMap contributors',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  LatLng? _parsePoint(dynamic raw) {
    if (raw is Map) {
      final lat = num.tryParse(
        (raw['latitude'] ?? raw['lat']).toString(),
      );
      final lng = num.tryParse(
        (raw['longitude'] ?? raw['lng'] ?? raw['lon']).toString(),
      );
      if (lat != null && lng != null && _valid(lat.toDouble(), lng.toDouble())) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    }

    if (raw is List && raw.length >= 2) {
      final lng = num.tryParse(raw[0].toString());
      final lat = num.tryParse(raw[1].toString());
      if (lat != null && lng != null && _valid(lat.toDouble(), lng.toDouble())) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    }

    if (raw is String) {
      final normalized = raw
          .replaceFirst(
            RegExp(r'^SRID=[^;]+;', caseSensitive: false),
            '',
          )
          .trim();

      final match = RegExp(
        r'^POINT\s*\(\s*([-+]?\d+(?:\.\d+)?)\s+([-+]?\d+(?:\.\d+)?)\s*\)    switch (status) {
      case 'CREATED':
        return 0.15;
      case 'READY_FOR_PICKUP':
      case 'ASSIGNED':
        return 0.35;
      case 'PICKED_UP':
        return 0.55;
      case 'IN_TRANSIT':
        return 0.75;
      case 'DELIVERED':
        return 1;
      default:
        return 0.1;
    }
  }
}
,
        caseSensitive: false,
      ).firstMatch(normalized);

      if (match != null) {
        final lng = double.tryParse(match.group(1)!);
        final lat = double.tryParse(match.group(2)!);
        if (lat != null && lng != null && _valid(lat, lng)) {
          return LatLng(lat, lng);
        }
      }
    }

    return null;
  }

  bool _valid(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180;

  double _progress(String? status) {
    switch (status) {
      case 'CREATED':
        return 0.15;
      case 'READY_FOR_PICKUP':
      case 'ASSIGNED':
        return 0.35;
      case 'PICKED_UP':
        return 0.55;
      case 'IN_TRANSIT':
        return 0.75;
      case 'DELIVERED':
        return 1;
      default:
        return 0.1;
    }
  }
}
