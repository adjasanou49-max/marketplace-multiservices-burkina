import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/transport_repository.dart';

final transportRepositoryProvider = Provider<TransportRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : TransportRepository(client);
});

class TransportPage extends ConsumerStatefulWidget {
  const TransportPage({super.key});

  @override
  ConsumerState<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends ConsumerState<TransportPage> {
  late Future<List<Map<String, dynamic>>> _tripsFuture;
  late Future<List<Map<String, dynamic>>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _loadTrips();
    _ticketsFuture = _loadTickets();
  }

  Future<List<Map<String, dynamic>>> _loadTrips() {
    return ref.read(transportRepositoryProvider)?.upcoming() ??
        Future.value(const []);
  }

  Future<List<Map<String, dynamic>>> _loadTickets() {
    final repo = ref.read(transportRepositoryProvider);
    if (repo == null || ref.read(supabaseProvider)?.auth.currentUser == null) {
      return Future.value(const []);
    }
    return repo.myTickets();
  }

  Future<void> _reserve(Map<String, dynamic> trip) async {
    final controller = TextEditingController();

    final passenger = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réserver un billet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom du passager',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Réserver'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (passenger == null) return;

    final repo = ref.read(transportRepositoryProvider);
    if (repo == null) return;

    try {
      final booking = await repo.reserve(
        tripId: trip['id'].toString(),
        passengerName: passenger,
      );

      if (!mounted) return;

      setState(() => _ticketsFuture = _loadTickets());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Réservation créée : ' + booking,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation impossible : ' + error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Départs disponibles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final trips =
                  snapshot.data ?? const <Map<String, dynamic>>[];

              if (trips.isEmpty) {
                return const Text('Aucun départ disponible.');
              }

              return Column(
                children: trips.map((trip) {
                  final route = trip['transport_routes'] is Map
                      ? Map<String, dynamic>.from(
                          trip['transport_routes'] as Map,
                        )
                      : const <String, dynamic>{};
                  final company = route['transport_companies'] is Map
                      ? Map<String, dynamic>.from(
                          route['transport_companies'] as Map,
                        )
                      : const <String, dynamic>{};
                  final departure = route['departure'] is Map
                      ? Map<String, dynamic>.from(route['departure'] as Map)
                      : const <String, dynamic>{};
                  final arrival = route['arrival'] is Map
                      ? Map<String, dynamic>.from(route['arrival'] as Map)
                      : const <String, dynamic>{};

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.directions_bus_outlined),
                      ),
                      title: Text(
                        (departure['name']?.toString() ?? '?') +
                            ' → ' +
                            (arrival['name']?.toString() ?? '?'),
                      ),
                      subtitle: Text(
                        (company['name']?.toString() ?? 'Compagnie') +
                            '\nDépart : ' +
                            (trip['departure_at']?.toString() ?? '') +
                            '\nPrix : ' +
                            (trip['price']?.toString() ?? '0') +
                            ' XOF',
                      ),
                      trailing: FilledButton(
                        onPressed: () => _reserve(trip),
                        child: const Text('Choisir'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Mes billets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _ticketsFuture,
            builder: (context, snapshot) {
              final tickets =
                  snapshot.data ?? const <Map<String, dynamic>>[];

              if (tickets.isEmpty) {
                return const Text('Aucun billet.');
              }

              return Column(
                children: tickets.map((ticket) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.confirmation_number_outlined),
                      title: Text(
                        ticket['passenger_name']?.toString() ?? 'Passager',
                      ),
                      subtitle: Text(
                        'Billet : ' +
                            (ticket['id']?.toString() ?? '-') +
                            '\nÉtat : ' +
                            (ticket['status']?.toString() ?? '-'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
