import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _addAssociate() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    final results = await Future.wait([
      client.from('company').select('id,legal_name').order('legal_name').limit(100),
      client.from('share_classes').select('id,company_id,name,nominal_value').order('name').limit(200),
      client.from('profiles').select('id,display_name,status').order('display_name').limit(500),
    ]);

    final companies = (results[0] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final shareClasses = (results[1] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final profiles = (results[2] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    if (!mounted) return;

    String? companyId;
    String? shareClassId;
    String? shareholderId;
    final sharesController = TextEditingController(text: '1');
    final amountController = TextEditingController();
    final referenceController = TextEditingController();

    final values = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final classesForCompany = companyId == null
              ? const <Map<String, dynamic>>[]
              : shareClasses.where(
                  (row) => row['company_id']?.toString() == companyId,
                ).toList();

          return AlertDialog(
            title: const Text('Ajouter un associé'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: companyId,
                    decoration: const InputDecoration(labelText: 'Société'),
                    items: companies.map((row) {
                      return DropdownMenuItem<String>(
                        value: row['id'].toString(),
                        child: Text(row['legal_name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        companyId = value;
                        shareClassId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: shareClassId,
                    decoration: const InputDecoration(labelText: 'Classe de parts'),
                    items: classesForCompany.map((row) {
                      return DropdownMenuItem<String>(
                        value: row['id'].toString(),
                        child: Text(
                          row['name'].toString() +
                              ' • ' +
                              row['nominal_value'].toString() +
                              ' XOF',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => shareClassId = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: shareholderId,
                    decoration: const InputDecoration(labelText: 'Utilisateur'),
                    items: profiles.map((row) {
                      final name = row['display_name']?.toString();
                      return DropdownMenuItem<String>(
                        value: row['id'].toString(),
                        child: Text(
                          (name == null || name.isEmpty)
                              ? row['id'].toString()
                              : name,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => shareholderId = value),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sharesController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Nombre de parts'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Montant payé',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Référence du paiement vérifié',
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
                onPressed: companyId != null &&
                        shareClassId != null &&
                        shareholderId != null &&
                        num.tryParse(sharesController.text.trim()) != null &&
                        num.tryParse(amountController.text.trim()) != null &&
                        referenceController.text.trim().isNotEmpty
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Valider'),
              ),
            ],
          );
        },
      ),
    );

    final parsedShares = num.tryParse(sharesController.text.trim());
    final parsedAmount = num.tryParse(amountController.text.trim());
    final paymentReference = referenceController.text.trim();

    sharesController.dispose();
    amountController.dispose();
    referenceController.dispose();

    if (values != true ||
        companyId == null ||
        shareClassId == null ||
        shareholderId == null ||
        parsedShares == null ||
        parsedAmount == null ||
        paymentReference.isEmpty) {
      return;
    }

    try {
      final holdingId = await client.rpc(
        'admin_add_associate_after_payment',
        params: {
          'p_company_id': companyId,
          'p_shareholder_id': shareholderId,
          'p_share_class_id': shareClassId,
          'p_shares': parsedShares,
          'p_paid_amount': parsedAmount,
          'p_payment_reference': paymentReference,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Associé activé : ' + holdingId.toString())),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activation refusée : ' + error.toString())),
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
              FilledButton.icon(
                onPressed: _addAssociate,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Ajouter un associé après paiement'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.push('/admin/accounts'),
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Gérer les comptes utilisateurs'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Les changements de compte, produit, livraison, remboursement, finance et associés passent par les RPC d’administration protégées.',
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
