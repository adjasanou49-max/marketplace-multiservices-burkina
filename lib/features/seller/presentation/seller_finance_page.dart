import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/seller_repository.dart';

final sellerFinanceRepositoryProvider = Provider<SellerRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : SellerRepository(client);
});

class SellerFinancePage extends ConsumerStatefulWidget {
  const SellerFinancePage({super.key});

  @override
  ConsumerState<SellerFinancePage> createState() => _SellerFinancePageState();
}

class _SellerFinancePageState extends ConsumerState<SellerFinancePage> {
  late Future<_FinanceSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FinanceSnapshot> _load() async {
    final repo = ref.read(sellerFinanceRepositoryProvider);
    if (repo == null) {
      throw StateError('Authentification requise.');
    }
    final sellerId = await repo.sellerId();
    if (sellerId == null) {
      throw StateError('Compte vendeur introuvable.');
    }

    final balance = await repo.balance(sellerId);
    final payouts = await repo.payouts(sellerId);
    final ledger = await repo.client
        .from('seller_ledger')
        .select('entry_type,amount,currency,reference_id,created_at')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .limit(100);

    return _FinanceSnapshot(
      sellerId: sellerId,
      balance: balance,
      payouts: payouts,
      ledger: (ledger as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance vendeur'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_FinanceSnapshot>(
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
                  'Chargement impossible : ' + snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Solde'),
                  subtitle: Text(data.sellerId),
                  trailing: Text(
                    data.balance.toString() + ' XOF',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Demandes de paiement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.payouts.isEmpty)
                const Text('Aucune demande de paiement.')
              else
                ...data.payouts.map(
                  (row) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(
                        (row['amount']?.toString() ?? '0') +
                            ' ' +
                            (row['currency']?.toString() ?? 'XOF'),
                      ),
                      subtitle: Text(
                        (row['provider']?.toString() ?? '-') +
                            ' • ' +
                            (row['status']?.toString() ?? '-'),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Journal financier',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...data.ledger.map(
                (row) => ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(row['entry_type']?.toString() ?? '-'),
                  subtitle: Text(row['created_at']?.toString() ?? '-'),
                  trailing: Text(
                    (row['amount']?.toString() ?? '0') +
                        ' ' +
                        (row['currency']?.toString() ?? 'XOF'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FinanceSnapshot {
  const _FinanceSnapshot({
    required this.sellerId,
    required this.balance,
    required this.payouts,
    required this.ledger,
  });

  final String sellerId;
  final num balance;
  final List<Map<String, dynamic>> payouts;
  final List<Map<String, dynamic>> ledger;
}
