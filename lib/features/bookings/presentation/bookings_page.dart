import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : BookingsRepository(client);
});

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  late Future<List<BookingRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BookingRecord>> _load() async {
    final repository = ref.read(bookingsRepositoryProvider);
    return repository?.currentUserRecords() ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<BookingRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Impossible de charger vos réservations.'));
          }
          final records = snapshot.data ?? const [];
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_note_outlined, size: 56),
                    const SizedBox(height: 12),
                    const Text('Aucune réservation ou demande enregistrée.', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Explorer les services'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final record = records[index];
                final when = record.scheduledAt ?? record.createdAt;
                final date = when == null ? 'Date indisponible' : _format(when.toLocal());
                final amount = record.amount == null ? null : '${record.amount!.toStringAsFixed(0)} XOF';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_icon(record.kind))),
                    title: Text(record.kind),
                    subtitle: Text([
                      'Statut : ${record.status}',
                      date,
                      if (amount != null) amount,
                      if (record.reference != null && record.reference!.isNotEmpty) 'Suivi : ${record.reference}',
                    ].join(' • ')),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _format(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} à $hour:$minute';
  }

  IconData _icon(String kind) {
    switch (kind) {
      case 'Transport': return Icons.directions_bus_outlined;
      case 'Événement': return Icons.event_outlined;
      case 'Location de véhicule': return Icons.car_rental_outlined;
      case 'Hébergement': return Icons.hotel_outlined;
      case 'Beauté': return Icons.content_cut_outlined;
      case 'Service': return Icons.handyman_outlined;
      case 'Formation': return Icons.school_outlined;
      case 'Service numérique': return Icons.devices_outlined;
      case 'Mécanicien': return Icons.build_outlined;
      case 'Trajet': return Icons.directions_car_outlined;
      case 'Fret': return Icons.local_shipping_outlined;
      case 'Colis': return Icons.inventory_2_outlined;
      default: return Icons.receipt_long_outlined;
    }
  }
}
