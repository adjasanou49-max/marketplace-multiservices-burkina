import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class ExpiryPage extends ConsumerStatefulWidget {
  const ExpiryPage({super.key});

  @override
  ConsumerState<ExpiryPage> createState() => _ExpiryPageState();
}

class _ExpiryPageState extends ConsumerState<ExpiryPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repo = ref.read(catalogRepositoryProvider);
    if (repo == null) return const [];

    final rows = await repo.products(limit: 100);
    final today = DateTime.now();
    final maxDate = today.add(const Duration(days: 30));
    final minDate = today.add(const Duration(days: 5));

    return rows.where((product) {
      if (product['is_expirable'] != true) return false;

      final raw = product['expiry_date'];
      if (raw == null) return false;

      final date = DateTime.tryParse(raw.toString());
      if (date == null) return false;

      return !date.isBefore(minDate) && !date.isAfter(maxDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiration proche'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur : ' + snapshot.error.toString(),
              ),
            );
          }

          final products =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Aucun produit avec une expiration entre 5 et 30 jours.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final product = products[index];

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.event_busy_outlined),
                  ),
                  title: Text(
                    product['name']?.toString() ?? 'Produit',
                  ),
                  subtitle: Text(
                    'Expiration : ' +
                        (product['expiry_date']?.toString() ?? '-') +
                        '\nPrix : ' +
                        (product['price']?.toString() ?? '0') +
                        ' XOF',
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
