import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class SellerClientsPage extends ConsumerStatefulWidget {
  const SellerClientsPage({super.key});

  @override
  ConsumerState<SellerClientsPage> createState() => _SellerClientsPageState();
}

class _SellerClientsPageState extends ConsumerState<SellerClientsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final client = ref.read(supabaseProvider);
    final result = await client?.rpc('get_seller_client_stats');
    if (result is! Map) throw StateError('Statistiques clients invalides.');
    return Map<String, dynamic>.from(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ' + snapshot.error.toString()));
          }
          final s = snapshot.data ?? const <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Metric(title: 'Clients uniques', value: s['total_clients']),
              _Metric(title: 'Clients récurrents', value: s['repeat_clients']),
              _Metric(title: 'Commandes', value: s['total_orders']),
              _Metric(title: 'Commandes livrées', value: s['delivered_orders']),
              const SizedBox(height: 12),
              const Text(
                'Les informations personnelles des acheteurs ne sont pas exposées ici. Le module fournit les indicateurs nécessaires au pilotage vendeur.',
              ),
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
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.people_outline),
        title: Text(title),
        trailing: Text(
          value?.toString() ?? '0',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
