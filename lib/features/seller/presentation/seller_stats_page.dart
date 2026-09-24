import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seller_repository.dart';
import '../../../core/providers/repository_providers.dart';

final sellerStatsRepositoryProvider = Provider<SellerRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : SellerRepository(client);
});

class SellerStatsPage extends ConsumerStatefulWidget {
  const SellerStatsPage({super.key});

  @override
  ConsumerState<SellerStatsPage> createState() => _SellerStatsPageState();
}

class _SellerStatsPageState extends ConsumerState<SellerStatsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repo = ref.read(sellerStatsRepositoryProvider);
    if (repo == null) throw StateError('Authentification requise.');
    return repo.dashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
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
            return Center(child: Text('Erreur : ' + snapshot.error.toString()));
          }

          final shops = snapshot.data ?? const <Map<String, dynamic>>[];
          final products = shops.fold<int>(
            0,
            (sum, row) => sum + ((row['active_products'] as num?)?.toInt() ?? 0),
          );
          final pending = shops.fold<int>(
            0,
            (sum, row) => sum + ((row['pending_orders'] as num?)?.toInt() ?? 0),
          );
          final delivered = shops.fold<int>(
            0,
            (sum, row) => sum + ((row['delivered_orders'] as num?)?.toInt() ?? 0),
          );
          final sales = shops.fold<num>(
            0,
            (sum, row) => sum + ((num.tryParse(row['gross_sales']?.toString() ?? '') ?? 0)),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Metric(title: 'Produits actifs', value: products.toString()),
              _Metric(title: 'Commandes en cours', value: pending.toString()),
              _Metric(title: 'Commandes livrées', value: delivered.toString()),
              _Metric(title: 'Ventes livrées', value: sales.toStringAsFixed(0) + ' XOF'),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(title),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
}
