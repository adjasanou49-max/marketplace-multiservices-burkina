import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/device_location_service.dart';
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
  late Future<List<Map<String, dynamic>>> _mechanicsFuture;
  late Future<List<Map<String, dynamic>>> _quotesFuture;
  late Future<bool> _isMechanicFuture;

  @override
  void initState() {
    super.initState();
    _mechanicsFuture = _loadMechanics();
    _quotesFuture = _loadQuotes();
    _isMechanicFuture = _loadOwnMechanic();
  }

  Future<List<Map<String, dynamic>>> _loadMechanics() {
    return ref.read(mechanicRepositoryProvider)?.mechanics() ??
        Future.value(const []);
  }

  Future<bool> _loadOwnMechanic() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return false;
    final rows = await client
        .from('mechanics')
        .select('id,display_name,active,verification_status')
        .eq('user_id', user.id)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> _manageAvailability() async {
    if (!await _loadOwnMechanic()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun profil mécanicien lié à ce compte.')),
        );
      }
      return;
    }

    final status = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Ma disponibilité'),
        children: const [
          SimpleDialogOption(
            value: 'AVAILABLE',
            child: Text('Disponible maintenant'),
          ),
          SimpleDialogOption(
            value: 'IN_10_MIN',
            child: Text('Disponible dans 10 min'),
          ),
          SimpleDialogOption(
            value: 'IN_20_MIN',
            child: Text('Disponible dans 20 min'),
          ),
          SimpleDialogOption(
            value: 'IN_30_MIN',
            child: Text('Disponible dans 30 min'),
          ),
          SimpleDialogOption(
            value: 'UNAVAILABLE',
            child: Text('Indisponible'),
          ),
        ],
      ),
    );

    if (status == null) return;

    try {
      final client = ref.read(supabaseProvider);
      await client?.rpc(
        'set_mechanic_availability',
        params: {
          'p_status': status,
          'p_starts_at': DateTime.now().toUtc().toIso8601String(),
          'p_ends_at': null,
        },
      );

      final vacation = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        helpText: 'Programmer un congé (facultatif)',
      );

      if (vacation != null && mounted) {
        final reason = await showDialog<String>(
          context: context,
          builder: (dialogContext) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text('Période de congé'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Motif (facultatif)',
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
                    controller.text.trim(),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );

        await client?.rpc(
          'schedule_mechanic_time_off',
          params: {
            'p_starts_at': DateTime(
              vacation.start.year,
              vacation.start.month,
              vacation.start.day,
            ).toUtc().toIso8601String(),
            'p_ends_at': DateTime(
              vacation.end.year,
              vacation.end.month,
              vacation.end.day,
              23,
              59,
              59,
            ).toUtc().toIso8601String(),
            'p_reason': reason,
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disponibilité mise à jour.')),
      );
      setState(() {
        _mechanicsFuture = _loadMechanics();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mise à jour refusée : ' + error.toString())),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuotes() {
    final client = ref.read(supabaseProvider);
    if (client?.auth.currentUser == null) return Future.value(const []);
    return ref.read(mechanicRepositoryProvider)?.myQuotes() ??
        Future.value(const []);
  }

  Future<void> _request() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _MechanicRequestDialog(),
    );

    if (result == null) return;

    try {
      final pos = await DeviceLocationService.current();
      final repo = ref.read(mechanicRepositoryProvider);
      if (repo == null) return;

      final id = await repo.createRequest(
        vehicleType: result['vehicle_type']!,
        problemType: result['problem_type']!,
        description: result['description'],
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      if (!mounted) return;

      setState(() => _quotesFuture = _loadQuotes());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demande envoyée. Référence : ' + id,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’envoyer la demande : ' + error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _accept(String quoteId) async {
    final repo = ref.read(mechanicRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.acceptQuote(quoteId);
      if (!mounted) return;
      setState(() => _quotesFuture = _loadQuotes());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Devis indisponible : ' + error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mécaniciens'),
        actions: [
          IconButton(
            onPressed: _request,
            icon: const Icon(Icons.car_repair_outlined),
            tooltip: 'Demander un mécanicien',
          ),
          FutureBuilder<bool>(
            future: _isMechanicFuture,
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return IconButton(
                onPressed: _manageAvailability,
                icon: const Icon(Icons.schedule_outlined),
                tooltip: 'Gérer ma disponibilité',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Mécaniciens disponibles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _mechanicsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items =
                  snapshot.data ?? const <Map<String, dynamic>>[];

              if (items.isEmpty) {
                return const Text('Aucun mécanicien vérifié disponible.');
              }

              return Column(
                children: items.map((mechanic) {
                  final raw = mechanic['mechanic_availability'];
                  final availability =
                      raw is List && raw.isNotEmpty
                          ? Map<String, dynamic>.from(raw.first as Map)
                          : null;

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.build_outlined),
                      ),
                      title: Text(
                        mechanic['display_name']?.toString() ?? 'Mécanicien',
                      ),
                      subtitle: Text(
                        _availabilityLabel(
                          availability?['status']?.toString(),
                        ) +
                            '\nRayon : ' +
                            (mechanic['service_radius_km']?.toString() ??
                                '-') +
                            ' km',
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Mes devis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _quotesFuture,
            builder: (context, snapshot) {
              final quotes =
                  snapshot.data ?? const <Map<String, dynamic>>[];

              if (quotes.isEmpty) {
                return const Text('Aucun devis reçu.');
              }

              return Column(
                children: quotes.map((quote) {
                  final mechanic = quote['mechanics'] is Map
                      ? Map<String, dynamic>.from(
                          quote['mechanics'] as Map,
                        )
                      : const <String, dynamic>{};

                  return Card(
                    child: ListTile(
                      title: Text(
                        mechanic['display_name']?.toString() ?? 'Mécanicien',
                      ),
                      subtitle: Text(
                        (quote['diagnosis']?.toString() ?? '') +
                            '\n' +
                            (quote['amount']?.toString() ?? '0') +
                            ' ' +
                            (quote['currency']?.toString() ?? 'XOF') +
                            ' • ' +
                            (quote['status']?.toString() ?? ''),
                      ),
                      trailing: quote['status'] == 'PENDING'
                          ? FilledButton(
                              onPressed: () =>
                                  _accept(quote['id'].toString()),
                              child: const Text('Accepter'),
                            )
                          : null,
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

  String _availabilityLabel(String? value) {
    switch (value) {
      case 'AVAILABLE':
        return 'Disponible maintenant';
      case 'IN_10_MIN':
        return 'Disponible dans 10 min';
      case 'IN_20_MIN':
        return 'Disponible dans 20 min';
      case 'IN_30_MIN':
        return 'Disponible dans 30 min';
      case 'UNAVAILABLE':
        return 'Indisponible';
      default:
        return 'Indisponible';
    }
  }
}

class _MechanicRequestDialog extends StatefulWidget {
  const _MechanicRequestDialog();

  @override
  State<_MechanicRequestDialog> createState() =>
      _MechanicRequestDialogState();
}

class _MechanicRequestDialogState extends State<_MechanicRequestDialog> {
  String _vehicle = 'CAR';
  final _problem = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _problem.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Demander un mécanicien'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _vehicle,
            decoration: const InputDecoration(labelText: 'Véhicule'),
            items: const [
              DropdownMenuItem(value: 'CAR', child: Text('Voiture')),
              DropdownMenuItem(
                value: 'MOTORCYCLE',
                child: Text('Moto'),
              ),
              DropdownMenuItem(
                value: 'BICYCLE',
                child: Text('Vélo'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _vehicle = value);
            },
          ),
          TextField(
            controller: _problem,
            decoration: const InputDecoration(
              labelText: 'Problème',
              hintText: 'Pneu crevé, plus d’essence…',
            ),
          ),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Détails',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (_problem.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              {
                'vehicle_type': _vehicle,
                'problem_type': _problem.text.trim(),
                'description': _description.text.trim(),
              },
            );
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
