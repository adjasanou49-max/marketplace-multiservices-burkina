import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/address_controller.dart';

class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes adresses')),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final a = items[i];
            return ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(a.label?.isNotEmpty == true ? a.label! : a.recipientName),
              subtitle: Text([a.addressLine, a.city].whereType<String>().where((x) => x.isNotEmpty).join(', ')),
              trailing: a.isDefault ? const Icon(Icons.check_circle) : null,
            );
          },
        ),
      ),
    );
  }
}
