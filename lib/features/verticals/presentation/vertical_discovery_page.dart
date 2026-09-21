import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/device_location_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/vertical_repository.dart';

final verticalRepositoryProvider = Provider<VerticalRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : VerticalRepository(client);
});

class VerticalDiscoveryPage extends ConsumerStatefulWidget {
  const VerticalDiscoveryPage({
    required this.module,
    super.key,
  });

  final VerticalModule module;

  @override
  ConsumerState<VerticalDiscoveryPage> createState() =>
      _VerticalDiscoveryPageState();
}

class _VerticalDiscoveryPageState
    extends ConsumerState<VerticalDiscoveryPage> {
  late Future<List<Map<String, dynamic>>> _future;

  VerticalConfig get config => VerticalRepository.configs[widget.module]!;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final repo = ref.read(verticalRepositoryProvider);
    return repo?.list(widget.module) ?? Future.value(const []);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  bool get _requiresAuth =>
      widget.module == VerticalModule.rides ||
      widget.module == VerticalModule.freight ||
      widget.module == VerticalModule.parcels;

  Future<bool> _ensureAuth() async {
    final client = ref.read(supabaseProvider);
    if (client?.auth.currentUser != null) return true;
    _info('Connectez-vous pour continuer.');
    return false;
  }

  Future<void> _act(Map<String, dynamic> item) async {
    final repo = ref.read(verticalRepositoryProvider);
    if (repo == null || !await _ensureAuth()) return;

    try {
      switch (widget.module) {
        case VerticalModule.rides:
          await _requestRide(repo);
        case VerticalModule.events:
          final quantity = await _quantityDialog('Nombre de billets');
          if (quantity == null) return;
          final id = await repo.reserveEvent(
            eventId: item['id'].toString(),
            quantity: quantity,
          );
          _success('Réservation créée : $id');
        case VerticalModule.rentals:
          final range = await _dateRangeDialog();
          if (range == null) return;
          final id = await repo.bookRental(
            rentalId: item['id'].toString(),
            startsAt: range.start,
            endsAt: range.end,
          );
          _success('Demande de location créée : $id');
        case VerticalModule.accommodations:
          final rawUnits = item['accommodation_units'];
          if (rawUnits is! List || rawUnits.isEmpty) {
            _info('Aucune chambre/unité disponible.');
            return;
          }
          final units = rawUnits
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final selected = await _unitDialog(units);
          if (selected == null) return;
          final stay = await _stayDialog();
          if (stay == null) return;
          final guests = await _quantityDialog('Nombre de personnes');
          if (guests == null) return;
          final id = await repo.bookAccommodation(
            unitId: selected['id'].toString(),
            checkIn: stay.start,
            checkOut: stay.end,
            guests: guests,
          );
          _success('Demande d’hébergement créée : $id');
        case VerticalModule.jobs:
          final id = await repo.applyToJob(item['id'].toString());
          _success('Candidature envoyée : $id');
        case VerticalModule.training:
          final id = await repo.enrollTraining(item['id'].toString());
          _success('Inscription créée : $id');
        case VerticalModule.digital:
          final id = await repo.orderDigital(item['id'].toString());
          _success('Commande numérique créée : $id');
        case VerticalModule.beauty:
          final dateTime = await _pickDateTime();
          if (dateTime == null) return;
          final id = await repo.bookBeauty(
            serviceId: item['id'].toString(),
            scheduledAt: dateTime,
          );
          _success('Rendez-vous demandé : $id');
        case VerticalModule.homeServices:
          final dateTime = await _pickDateTime();
          if (dateTime == null) return;
          final address = await _addressDialog();
          if (address == null) return;
          final id = await repo.requestHomeService(
            serviceId: item['id'].toString(),
            scheduledAt: dateTime,
            address: {'label': address},
          );
          _success('Demande à domicile créée : $id');
        case VerticalModule.freight:
          await _createFreight(repo);
        case VerticalModule.parcels:
          await _createParcel(repo);
        default:
          break;
      }
    } catch (error) {
      _info('Opération impossible : $error');
    }
  }

  Future<void> _trackParcel() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suivre un colis'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Code de suivi',
            hintText: 'PKG-XXXXXXXXXXXX',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Suivre'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null) return;

    final repo = ref.read(verticalRepositoryProvider);
    if (repo == null) return;

    try {
      final tracking = await repo.trackParcel(code);
      if (!mounted) return;
      final rawEvents = tracking['events'];
      final events = rawEvents is List
          ? rawEvents
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList()
          : const <Map<String, dynamic>>[];

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            'Colis ' + (tracking['tracking_code']?.toString() ?? code),
          ),
          content: SizedBox(
            width: 460,
            child: events.isEmpty
                ? Text(
                    'Statut actuel : ' +
                        (tracking['status']?.toString() ?? '-'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Statut actuel'),
                        subtitle: Text(
                          tracking['status']?.toString() ?? '-',
                        ),
                      ),
                      const Divider(),
                      for (final event in events)
                        ListTile(
                          leading: const Icon(Icons.route_outlined),
                          title: Text(
                            event['status']?.toString() ?? '-',
                          ),
                          subtitle: Text(
                            event['created_at']?.toString() ?? '-',
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (error) {
      _info('Suivi impossible : ' + error.toString());
    }
  }

  Future<void> _createFreight(VerticalRepository repo) async {
    final pickup = await _addressDialog();
    if (pickup == null) return;
    final destination = await _addressDialog();
    if (destination == null) return;
    final weight = TextEditingController();
    final description = TextEditingController();

    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle demande de fret'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Poids en kg (facultatif)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description de la marchandise',
                border: OutlineInputBorder(),
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
              <String>[weight.text.trim(), description.text.trim()],
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    weight.dispose();
    description.dispose();
    if (values == null) return;

    try {
      final id = await repo.createFreight(
        pickup: {'label': pickup},
        delivery: {'label': destination},
        weightKg: num.tryParse(values[0]),
        description: values[1].isEmpty ? null : values[1],
      );
      _success('Demande de fret créée : $id');
    } catch (error) {
      _info('Demande de fret impossible : $error');
    }
  }

  Future<void> _createParcel(VerticalRepository repo) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final pickup = TextEditingController();
    final delivery = TextEditingController();
    final weight = TextEditingController();

    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Envoyer un colis'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom du destinataire'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone du destinataire'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pickup,
                decoration: const InputDecoration(labelText: 'Lieu de dépôt / départ'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: delivery,
                decoration: const InputDecoration(labelText: 'Lieu de livraison'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Poids en kg (facultatif)'),
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
            onPressed: () {
              if (name.text.trim().isEmpty ||
                  pickup.text.trim().isEmpty ||
                  delivery.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                dialogContext,
                <String>[
                  name.text.trim(),
                  phone.text.trim(),
                  pickup.text.trim(),
                  delivery.text.trim(),
                  weight.text.trim(),
                ],
              );
            },
            child: const Text('Créer le colis'),
          ),
        ],
      ),
    );

    name.dispose();
    phone.dispose();
    pickup.dispose();
    delivery.dispose();
    weight.dispose();

    if (values == null) return;

    try {
      final id = await repo.createParcel(
        recipientName: values[0],
        recipientPhone: values[1],
        pickupAddress: {'label': values[2]},
        deliveryAddress: {'label': values[3]},
        weightKg: num.tryParse(values[4]),
      );
      _success('Colis créé : $id');
    } catch (error) {
      _info('Création du colis impossible : $error');
    }
  }

  Future<void> _requestRide(VerticalRepository repo) async {
    try {
      final position = await DeviceLocationService.current();
      final destination = await _destinationDialog();
      if (destination == null) return;

      final id = await repo.createRide(
        pickup: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
        destination: {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
          'label': destination.label,
        },
      );
      _success('Trajet demandé : $id');
    } catch (error) {
      _info(error.toString());
    }
  }

  Future<int?> _quantityDialog(String title) async {
    final controller = TextEditingController(text: '1');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantité',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0 && parsed <= 20) {
                Navigator.pop(dialogContext, parsed);
              }
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<String?> _addressDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adresse d’intervention'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Quartier, rue, repère...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<_Destination?> _destinationDialog() async {
    final lat = TextEditingController();
    final lng = TextEditingController();
    final label = TextEditingController();
    final value = await showDialog<_Destination>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Destination'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: label,
                decoration: const InputDecoration(
                  labelText: 'Repère / destination',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lng,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Longitude'),
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
            onPressed: () {
              final parsedLat = double.tryParse(lat.text.trim());
              final parsedLng = double.tryParse(lng.text.trim());
              if (parsedLat != null &&
                  parsedLng != null &&
                  parsedLat >= -90 &&
                  parsedLat <= 90 &&
                  parsedLng >= -180 &&
                  parsedLng <= 180) {
                Navigator.pop(
                  dialogContext,
                  _Destination(
                    latitude: parsedLat,
                    longitude: parsedLng,
                    label: label.text.trim(),
                  ),
                );
              }
            },
            child: const Text('Demander'),
          ),
        ],
      ),
    );
    lat.dispose();
    lng.dispose();
    label.dispose();
    return value;
  }

  Future<DateTime?> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<DateTimeRange?> _dateRangeDialog() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now().add(const Duration(days: 1)),
        end: DateTime.now().add(const Duration(days: 2)),
      ),
    );
    if (range == null) return null;
    return DateTimeRange(
      start: DateTime(range.start.year, range.start.month, range.start.day, 9),
      end: DateTime(range.end.year, range.end.month, range.end.day, 18),
    );
  }

  Future<DateTimeRange?> _stayDialog() => _dateRangeDialog();

  Future<Map<String, dynamic>?> _unitDialog(
    List<Map<String, dynamic>> units,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choisir une chambre / unité'),
        children: units.map((unit) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, unit),
            child: ListTile(
              title: Text(unit['name']?.toString() ?? 'Unité'),
              subtitle: Text(
                (unit['price_per_night']?.toString() ?? '0') +
                    ' XOF / nuit • capacité ' +
                    (unit['capacity']?.toString() ?? '0'),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _success(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() => _future = _load());
  }

  void _info(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool _hasAction(VerticalModule module) => const {
        VerticalModule.rentals,
        VerticalModule.accommodations,
        VerticalModule.events,
        VerticalModule.jobs,
        VerticalModule.beauty,
        VerticalModule.homeServices,
        VerticalModule.digital,
        VerticalModule.training,
        VerticalModule.freight,
        VerticalModule.parcels,
      }.contains(module);

  String _actionLabel(VerticalModule module) {
    switch (module) {
      case VerticalModule.rides:
        return 'Demander';
      case VerticalModule.rentals:
      case VerticalModule.accommodations:
        return 'Réserver';
      case VerticalModule.events:
        return 'Billets';
      case VerticalModule.jobs:
        return 'Postuler';
      case VerticalModule.beauty:
        return 'Rendez-vous';
      case VerticalModule.homeServices:
        return 'Demander';
      case VerticalModule.digital:
        return 'Commander';
      case VerticalModule.training:
        return 'S’inscrire';
      case VerticalModule.freight:
        return 'Demander';
      case VerticalModule.parcels:
        return 'Envoyer';
      default:
        return 'Voir';
    }
  }

  IconData _icon(int value) {
    const icons = <IconData>[
      Icons.directions_car_outlined,
      Icons.directions_car_filled_outlined,
      Icons.home_work_outlined,
      Icons.hotel_outlined,
      Icons.event_outlined,
      Icons.work_outline,
      Icons.engineering_outlined,
      Icons.agriculture_outlined,
      Icons.local_shipping_outlined,
      Icons.health_and_safety_outlined,
      Icons.content_cut_outlined,
      Icons.home_repair_service_outlined,
      Icons.devices_outlined,
      Icons.school_outlined,
      Icons.camera_alt_outlined,
      Icons.inventory_2_outlined,
    ];
    return icons[value.clamp(0, icons.length - 1).toInt()];
  }

  String _title(Map<String, dynamic> item) {
    switch (widget.module) {
      case VerticalModule.realEstate:
        return item['title']?.toString() ?? 'Bien immobilier';
      case VerticalModule.events:
        return item['title']?.toString() ?? 'Événement';
      case VerticalModule.jobs:
        return item['title']?.toString() ?? 'Offre d’emploi';
      case VerticalModule.training:
        return item['title']?.toString() ?? 'Formation';
      case VerticalModule.accommodations:
        return item['name']?.toString() ?? 'Hébergement';
      default:
        return item['name']?.toString() ??
            item['vehicle_type']?.toString() ??
            item['profession']?.toString() ??
            'Annonce';
    }
  }

  String _subtitle(Map<String, dynamic> item) {
    final price = item['price'] ??
        item['daily_price'] ??
        item['starting_price'] ??
        item['hourly_rate'] ??
        item['ticket_price'];

    final base = <String>[
      if (item['city'] != null) item['city'].toString(),
      if (item['location'] != null) item['location'].toString(),
      if (item['service_area'] != null) item['service_area'].toString(),
      if (item['vehicle_type'] != null) item['vehicle_type'].toString(),
      if (price != null) '$price XOF',
    ];

    return base.isNotEmpty
        ? base.join(' • ')
        : item['description']?.toString() ?? 'Voir les détails';
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.title),
        actions: [
          if (widget.module == VerticalModule.parcels)
            IconButton(
              tooltip: 'Suivre un colis',
              onPressed: _trackParcel,
              icon: const Icon(Icons.qr_code_scanner_outlined),
            ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: widget.module == VerticalModule.rides
          ? FloatingActionButton.extended(
              onPressed: () async {
                final repo = ref.read(verticalRepositoryProvider);
                if (repo != null && await _ensureAuth()) {
                  await _requestRide(repo);
                }
              },
              icon: const Icon(Icons.local_taxi_outlined),
              label: const Text('Nouveau trajet'),
            )
          : null,
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

          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            final message = _requiresAuth && client?.auth.currentUser == null
                ? 'Connectez-vous pour voir vos demandes.'
                : 'Aucune offre disponible actuellement.';
            return Center(child: Text(message));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final item = items[index];
              final action = _hasAction(widget.module);

              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(child: Icon(_icon(config.icon))),
                  title: Text(_title(item)),
                  subtitle: Text(_subtitle(item)),
                  trailing: action
                      ? FilledButton(
                          onPressed: () => _act(item),
                          child: Text(_actionLabel(widget.module)),
                        )
                      : null,
                  children: [
                    if (item['description'] != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(item['description'].toString()),
                        ),
                      ),
                    if (item['address'] != null)
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(item['address'].toString()),
                      ),
                    if (item['status'] != null)
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Statut'),
                        subtitle: Text(item['status'].toString()),
                      ),
                    if (item['tracking_code'] != null)
                      ListTile(
                        leading: const Icon(Icons.qr_code_2_outlined),
                        title: const Text('Code de suivi'),
                        subtitle: Text(item['tracking_code'].toString()),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}
