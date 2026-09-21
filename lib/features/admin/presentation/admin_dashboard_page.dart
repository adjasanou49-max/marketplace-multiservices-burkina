import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends ConsumerState<AdminDashboardPage> {
  late Future<_AdminSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminSnapshot> _load() async {
    final client = ref.read(supabaseProvider);

    if (client == null || client.auth.currentUser == null) {
      throw StateError('Authentification requise.');
    }

    final dashboard = await client.rpc('get_admin_dashboard');
    final moduleRows = await client
        .from('marketplace_modules')
        .select('key,label,route,enabled,sort_order')
        .order('sort_order')
        .limit(100);

    final map = dashboard is Map
        ? Map<String, dynamic>.from(dashboard)
        : const <String, dynamic>{};

    final modules = (moduleRows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    return _AdminSnapshot(
      metrics: map,
      modules: modules,
    );
  }

  Future<void> _toggleModule(
    Map<String, dynamic> module,
    bool enabled,
  ) async {
    final client = ref.read(supabaseProvider);

    if (client == null) return;

    try {
      await client.rpc(
        'admin_set_marketplace_module_enabled',
        params: {
          'p_key': module['key'],
          'p_enabled': enabled,
        },
      );

      if (!mounted) return;
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Modification refusée : ' + error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_AdminSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Accès ou chargement impossible : ' +
                      snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          }

          final metrics = data.metrics;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'Vue d’ensemble',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Metric('Utilisateurs', metrics['users']),
                  _Metric('Vendeurs', metrics['sellers']),
                  _Metric('Boutiques', metrics['shops']),
                  _Metric('Produits actifs', metrics['active_products']),
                  _Metric('Commandes', metrics['orders']),
                  _Metric('Support ouvert', metrics['open_support']),
                  _Metric('Fraudes à traiter', metrics['fraud_reports']),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Modules marketplace',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final module in data.modules)
                Card(
                  child: SwitchListTile(
                    title: Text(
                      module['label']?.toString() ?? module['key'].toString(),
                    ),
                    subtitle: Text(
                      module['route']?.toString() ?? '',
                    ),
                    value: module['enabled'] == true,
                    onChanged: (value) =>
                        _toggleModule(module, value),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Les changements de compte, produit, livraison, remboursement et finance continuent de passer par les RPC d’administration protégées.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminSnapshot {
  const _AdminSnapshot({
    required this.metrics,
    required this.modules,
  });

  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> modules;
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '0',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
