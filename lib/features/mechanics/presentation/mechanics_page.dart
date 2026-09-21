import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/mechanic_repository.dart';

final mechanicRepositoryProvider = Provider<MechanicRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : MechanicRepository(client);
});

class MechanicsPage extends ConsumerWidget {
  const MechanicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(mechanicRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mécaniciens')),
      body: repository == null
          ? const Center(child: Text('Supabase non configuré'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.activeMechanics(),
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
                    child: Text('Aucun mécanicien disponible actuellement.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final row = rows[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.build_outlined),
                      ),
                      title: Text(
                        row['display_name']?.toString() ?? 'Mécanicien',
                      ),
                      subtitle: Text(
                        '${row['verification_status'] ?? 'UNVERIFIED'} • Rayon ${row['service_radius_km'] ?? '—'} km',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                );
              },
            ),
    );
  }
}
