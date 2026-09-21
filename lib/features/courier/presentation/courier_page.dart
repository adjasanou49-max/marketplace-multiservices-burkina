import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/courier_repository.dart';
import '../domain/delivery_assignment.dart';

final courierRepositoryProvider = Provider<CourierRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : CourierRepository(client);
});

final courierAssignmentsProvider =
    FutureProvider<List<DeliveryAssignment>>((ref) async {
  final repo = ref.watch(courierRepositoryProvider);
  if (repo == null) return const [];
  return repo.assignments();
});

class CourierPage extends ConsumerWidget {
  const CourierPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courierAssignmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Espace livreur')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('Aucune livraison'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              final packageId = item.packageId.length > 8
                  ? item.packageId.substring(0, 8)
                  : item.packageId;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text('Colis $packageId'),
                  subtitle: Text(item.status),
                  trailing: Text(
                    item.assignedAt.toLocal().toString().substring(0, 16),
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
