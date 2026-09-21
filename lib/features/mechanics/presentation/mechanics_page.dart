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

  Future<void> _createRequest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final repository = ref.read(mechanicRepositoryProvider);
    if (repository == null) return;

    var vehicleType = 'MOTORCYCLE';
    final problemController = TextEditingController();
    final descriptionController = TextEditingController();

    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Demander un dépannage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: vehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Véhicule',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'CAR',
                      child: Text('Voiture'),
                    ),
                    DropdownMenuItem(
                      value: 'MOTORCYCLE',
                      child: Text('Moto'),
                    ),
                    DropdownMenuItem(
                      value: 'BICYCLE',
                      child: Text('Vélo'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(
                    () => vehicleType = value ?? vehicleType,
                  ),
                ),
                TextField(
                  controller: problemController,
                  decoration: const InputDecoration(
                    labelText: 'Problème',
                    hintText: 'Pneu crevé, panne, carburant...',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Détails',
                  ),
                ),
              ],
            ),
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
                  'vehicle': vehicleType,
                  'problem': problemController.text.trim(),
                  'description': descriptionController.text.trim(),
                },
              ),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );

    problemController.dispose();
    descriptionController.dispose();

    if (!context.mounted || data == null) return;

    final problem = data['problem']?.trim() ?? '';
    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Décrivez le problème rencontré.')),
      );
      return;
    }

    try {
      final requestId = await repository.createRequest(
        vehicleType: data['vehicle'] ?? 'MOTORCYCLE',
        problemType: problem,
        description: data['description'],
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande envoyée : $requestId')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur dépannage : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(mechanicRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mécaniciens'),
        actions: [
          IconButton(
            onPressed: () => _createRequest(context, ref),
            icon: const Icon(Icons.sos_outlined),
            tooltip: 'Dépannage',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createRequest(context, ref),
        icon: const Icon(Icons.build_outlined),
        label: const Text('Dépannage'),
      ),
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
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
