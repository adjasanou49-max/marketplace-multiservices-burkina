import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/transport_repository.dart';

final transportRepositoryProvider = Provider<TransportRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : TransportRepository(client);
});

class TransportPage extends ConsumerWidget {
  const TransportPage({super.key});

  Future<void> _book(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> trip,
  ) async {
    final repository = ref.read(transportRepositoryProvider);
    if (repository == null) return;

    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Réserver un trajet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du passager',
              ),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre de billets',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              {
                'name': nameController.text.trim(),
                'quantity': quantityController.text.trim(),
              },
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    nameController.dispose();
    quantityController.dispose();

    if (!context.mounted || data == null) return;

    final name = data['name']?.trim() ?? '';
    final quantity = int.tryParse(data['quantity'] ?? '1') ?? 0;
    if (name.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et quantité valides requis.')),
      );
      return;
    }

    try {
      final bookingId = await repository.bookTrip(
        tripId: trip['id'].toString(),
        quantity: quantity,
        passengerName: name,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation créée : $bookingId')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réservation : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(transportRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Compagnies de transport')),
      body: repository == null
          ? const Center(child: Text('Supabase non configuré'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.upcomingTrips(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                final rows = snapshot.data ?? const [];
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('Aucun départ disponible actuellement.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final row = rows[index];
                    final routeId = row['route_id']?.toString() ?? '';
                    final routeLabel = routeId.length > 8
                        ? routeId.substring(0, 8)
                        : routeId;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.directions_bus_outlined),
                        ),
                        title: Text('Trajet #$routeLabel'),
                        subtitle: Text(
                          '${row['departure_at'] ?? '—'} → ${row['arrival_at'] ?? '—'}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => _book(context, ref, row),
                          child: Text('${row['price'] ?? 0} XOF'),
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
