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
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.directions_bus_outlined),
                      ),
                      title: Text('Trajet #$routeLabel'),
                      subtitle: Text(
                        '${row['departure_at'] ?? '—'} → ${row['arrival_at'] ?? '—'}',
                      ),
                      trailing: Text('${row['price'] ?? 0} XOF'),
                    );
                  },
                );
              },
            ),
    );
  }
}
