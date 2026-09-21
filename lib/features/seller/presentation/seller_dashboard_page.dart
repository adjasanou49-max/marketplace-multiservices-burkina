import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/seller_repository.dart';

final sellerRepositoryProvider = Provider<SellerRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : SellerRepository(client);
});

class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() =>
      _SellerDashboardPageState();
}

class _SellerDashboardPageState
    extends ConsumerState<SellerDashboardPage> {
  late Future<List<Map<String, dynamic>>> _dashboardFuture;
  late Future<num> _balanceFuture;
  String? _sellerId;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
    _balanceFuture = _loadBalance();
  }

  Future<List<Map<String, dynamic>>> _loadDashboard() {
    final repo = ref.read(sellerRepositoryProvider);
    if (repo == null) return Future.value(const []);
    return repo.dashboard();
  }

  Future<num> _loadBalance() async {
    final repo = ref.read(sellerRepositoryProvider);
    if (repo == null) return 0;

    _sellerId = await repo.sellerId();
    if (_sellerId == null) return 0;

    return repo.balance(_sellerId!);
  }

  Future<void> _requestPayout() async {
    final sellerId = _sellerId;
    if (sellerId == null) return;

    final controller = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PayoutDialog(
        controller: controller,
      ),
    );

    controller.dispose();

    if (result == null) return;

    final amount =
        num.tryParse(result['amount']?.toString() ?? '') ?? 0;
    final provider = result['provider']?.toString() ?? '';

    if (amount <= 0 || provider.isEmpty) return;

    final repo = ref.read(sellerRepositoryProvider);
    if (repo == null) return;

    try {
      final payoutId = await repo.requestPayout(
        sellerId: sellerId,
        amount: amount,
        provider: provider,
      );

      if (!mounted) return;

      setState(() => _balanceFuture = _loadBalance());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demande de paiement créée : ' + payoutId,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demande impossible : ' + error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);

    if (client?.auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Espace vendeur')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.push('/auth'),
            child: const Text('Se connecter'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord vendeur'),
        actions: [
          IconButton(
            tooltip: 'Boutique',
            onPressed: () => context.push('/seller/shop'),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FutureBuilder<num>(
            future: _balanceFuture,
            builder: (context, snapshot) {
              final balance = snapshot.data ?? 0;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  title: const Text('Solde vendeur disponible'),
                  subtitle: Text(
                    balance.toStringAsFixed(0) + ' XOF',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _requestPayout,
                    child: const Text('Retirer'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text(
                  'Erreur vendeur : ' + snapshot.error.toString(),
                );
              }

              final shops =
                  snapshot.data ?? const <Map<String, dynamic>>[];

              if (shops.isEmpty) {
                return const Text(
                  'Aucune boutique vendeur active pour ce compte.',
                );
              }

              return Column(
                children: shops.map((shop) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop['shop_name']?.toString() ?? 'Boutique',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _Metric(
                                label: 'Produits actifs',
                                value: shop['active_products'],
                              ),
                              _Metric(
                                label: 'Commandes en cours',
                                value: shop['pending_orders'],
                              ),
                              _Metric(
                                label: 'Commandes livrées',
                                value: shop['delivered_orders'],
                              ),
                              _Metric(
                                label: 'Ventes',
                                value: (shop['gross_sales']?.toString() ??
                                        '0') +
                                    ' XOF',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Produits, Stock, Commandes, Finance, Promotions, Coupons, Avis, Clients et Statistiques sont maintenant raccordés au socle vendeur.',
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '0',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PayoutDialog extends StatefulWidget {
  const _PayoutDialog({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<_PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends State<_PayoutDialog> {
  String _provider = 'ORANGE_MONEY';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Demande de paiement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant',
              suffixText: 'XOF',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _provider,
            decoration: const InputDecoration(
              labelText: 'Opérateur',
            ),
            items: const [
              DropdownMenuItem(
                value: 'ORANGE_MONEY',
                child: Text('Orange Money'),
              ),
              DropdownMenuItem(
                value: 'WAVE',
                child: Text('Wave'),
              ),
              DropdownMenuItem(
                value: 'MOOV_MONEY',
                child: Text('Moov Money'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _provider = value);
            },
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
            Navigator.pop(
              context,
              {
                'amount': widget.controller.text.trim(),
                'provider': _provider,
              },
            );
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
