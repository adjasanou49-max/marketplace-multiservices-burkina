import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/mechanic_repository.dart';

final mechanicRepositoryProvider = Provider<MechanicRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : MechanicRepository(client);
});

class MechanicsPage extends ConsumerStatefulWidget {
  const MechanicsPage({super.key});

  @override
  ConsumerState<MechanicsPage> createState() => _MechanicsPageState();
}

class _MechanicsPageState extends ConsumerState<MechanicsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repository = ref.read(mechanicRepositoryProvider);
    if (repository == null) return const [];
    return repository.activeMechanics();
  }

  Future<void> _requestHelp() async {
    final repository = ref.read(mechanicRepositoryProvider);
    if (repository == null) return;

    final address = await repository.defaultCustomerAddress();
    if (!mounted) return;

    var selectedVehicle = 'MOTORBIKE';
    var selectedProblem = 'PNEU_CREVE';
    final descriptionController = TextEditingController();
    final latitude = address?['latitude'] as num?;
    final longitude = address?['longitude'] as num?;

    final request = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Demander un mécanicien'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedVehicle,
                  decoration: const InputDecoration(labelText: 'Véhicule'),
                  items: const [
                    DropdownMenuItem(value: 'MOTORBIKE', child: Text('Moto')),
                    DropdownMenuItem(value: 'CAR', child: Text('Voiture')),
                    DropdownMenuItem(value: 'BICYCLE', child: Text('Vélo')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedVehicle = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedProblem,
                  decoration: const InputDecoration(labelText: 'Problème'),
                  items: const [
                    DropdownMenuItem(
                      value: 'PNEU_CREVE',
                      child: Text('Pneu crevé'),
                    ),
                    DropdownMenuItem(
                      value: 'PLUS_ESSENCE',
                      child: Text("Panne d'essence"),
                    ),
                    DropdownMenuItem(
                      value: 'PANNE',
                      child: Text('Panne mécanique'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedProblem = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (latitude != null && longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Position par défaut : ${address?['city'] ?? 'adresse enregistrée'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Ajoutez une adresse avec GPS pour envoyer votre position.',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: latitude == null || longitude == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Envoyer la demande'),
            ),
          ],
        ),
      ),
    );

    if (request != true || latitude == null || longitude == null) {
      descriptionController.dispose();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = await repository.createRequest(
        vehicleType: selectedVehicle,
        problemType: selectedProblem,
        description: descriptionController.text,
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Demande créée : $id')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      descriptionController.dispose();
    }
  }
  String _availabilityLabel(String? status) {
    switch (status) {
      case 'AVAILABLE':
        return 'Disponible';
      case 'ETA_10':
        return 'Arrive dans ~10 min';
      case 'ETA_20':
        return 'Arrive dans ~20 min';
      case 'ETA_30':
        return 'Arrive dans ~30 min';
      case 'VACATION':
        return 'En congés';
      default:
        return 'Indisponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(mechanicRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mécaniciens'),
        actions: [
          IconButton(
            onPressed: () => setState(() => future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: repository == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _requestHelp,
              icon: const Icon(Icons.warning_amber_outlined),
              label: const Text('Besoin d’aide'),
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
              child: Text('Aucun mécanicien disponible actuellement.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final row = rows[index];
              final status = row['availability_status']?.toString();
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.build_outlined),
                ),
                title: Text(row['display_name']?.toString() ?? 'Mécanicien'),
                subtitle: Text(
                  '${_availabilityLabel(status)} • Rayon ${row['service_radius_km'] ?? '—'} km',
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