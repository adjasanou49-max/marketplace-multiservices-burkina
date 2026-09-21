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
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repository = ref.read(transportRepositoryProvider);
    if (repository == null) return const [];
    return repository.upcomingTrips();
  }

  Future<void> _book(Map<String, dynamic> trip) async {
    final repository = ref.read(transportRepositoryProvider);
    if (repository == null) return;

    final nameController = TextEditingController();
    var quantity = 1;
    final tripId = trip['id']?.toString() ?? '';
    final price = (trip['price'] as num?) ?? 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Réserver un voyage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du passager',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nombre de places'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity <= 1
                            ? null
                            : () => setDialogState(() => quantity--),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: () => setDialogState(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                'Total indicatif : ${(price * quantity).toStringAsFixed(0)} XOF',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: nameController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Réserver'),
            ),
          ],
        ),
      ),
    );

    if (result != true || tripId.isEmpty) {
      nameController.dispose();
      return;
    }

    try {
      final bookingId = await repository.createBooking(
        tripId: tripId,
        quantity: quantity,
        passengerName: nameController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation créée : $bookingId')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation impossible : $error')),
      );
    } finally {
      nameController.dispose();
    }
  }

  String _time(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(transportRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compagnies de transport'),
        actions: [
          IconButton(
            onPressed: () => setState(() => future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const Center(
              child: Text('Aucun départ disponible actuellement.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final row = rows[index];
              final company = row['company'] is Map
                  ? Map<String, dynamic>.from(row['company'])
                  : const <String, dynamic>{};
              final departure = row['departure_station'] is Map
                  ? Map<String, dynamic>.from(row['departure_station'])
                  : const <String, dynamic>{};
              final arrival = row['arrival_station'] is Map
                  ? Map<String, dynamic>.from(row['arrival_station'])
                  : const <String, dynamic>{};
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.directions_bus_outlined),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              company['name']?.toString() ?? 'Compagnie',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${row['price'] ?? 0} XOF',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${departure['name'] ?? 'Départ'} → ${arrival['name'] ?? 'Arrivée'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_time(row['departure_at'])} → ${_time(row['arrival_at'])}',
                      ),
                      if (row['route'] is Map)
                        Text(
                          'Durée : ${(row['route']['duration_minutes'] ?? '—').toString()} min',
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: repository == null ? null : () => _book(row),
                          icon: const Icon(Icons.confirmation_num_outlined),
                          label: const Text('Réserver'),
                        ),
                      ),
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
}