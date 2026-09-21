import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/location/device_location_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/courier_repository.dart';

final courierRepositoryProvider = Provider<CourierRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : CourierRepository(client);
});

class CourierPage extends ConsumerStatefulWidget {
  const CourierPage({super.key});

  @override
  ConsumerState<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends ConsumerState<CourierPage> {
  late Future<List<Map<String, dynamic>>> _future;
  Timer? _locationTimer;
  bool _sharingLocation = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final repo = ref.read(courierRepositoryProvider);
    if (repo == null) return Future.value(const []);
    return repo.assignments();
  }

  Future<void> _toggleLocation() async {
    if (_sharingLocation) {
      _locationTimer?.cancel();
      setState(() => _sharingLocation = false);
      return;
    }

    try {
      await _recordLocation();
      _locationTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _recordLocation(),
      );
      setState(() => _sharingLocation = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Localisation indisponible : ' + error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _recordLocation() async {
    final repo = ref.read(courierRepositoryProvider);
    if (repo == null) return;

    final Position position = await DeviceLocationService.current();

    await repo.recordLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  Future<void> _action(
    Map<String, dynamic> assignment,
    String action,
  ) async {
    final repo = ref.read(courierRepositoryProvider);
    if (repo == null) return;

    try {
      if (action == 'accept') {
        await repo.accept(assignment['id'].toString());
      } else {
        await repo.start(assignment['package_id'].toString());
      }

      if (!mounted) return;
      setState(() => _future = _load());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mise à jour enregistrée.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action impossible : ' + error.toString())),
      );
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace livreur'),
        actions: [
          IconButton(
            tooltip: 'Partager ma position',
            onPressed: _toggleLocation,
            icon: Icon(
              _sharingLocation
                  ? Icons.location_on
                  : Icons.location_off_outlined,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur : ' + snapshot.error.toString()),
            );
          }

          final items =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (items.isEmpty) {
            return const Center(
              child: Text('Aucune livraison affectée.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = items[index];
              final status = item['status']?.toString();

              return Card(
                child: ListTile(
                  title: Text(
                    'Colis ' + (item['package_id']?.toString() ?? '-'),
                  ),
                  subtitle: Text(
                    'État : ' +
                        (status ?? '-') +
                        '\nAffecté le : ' +
                        (item['assigned_at']?.toString() ?? '-'),
                  ),
                  trailing: _actions(item, status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actions(
    Map<String, dynamic> item,
    String? status,
  ) {
    if (status == 'ASSIGNED') {
      return FilledButton(
        onPressed: () => _action(item, 'accept'),
        child: const Text('Accepter'),
      );
    }

    if (status == 'ACCEPTED' || status == 'PICKED_UP') {
      return FilledButton.tonal(
        onPressed: () => _action(item, 'start'),
        child: const Text('Démarrer'),
      );
    }

    return const Icon(Icons.check_circle_outline);
  }
}
