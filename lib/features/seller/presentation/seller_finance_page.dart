import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seller_repository.dart';

class SellerFinancePage extends ConsumerStatefulWidget {
  const SellerFinancePage({super.key});

  @override
  ConsumerState<SellerFinancePage> createState() =>
      _SellerFinancePageState();
}

class _SellerFinancePageState
    extends ConsumerState<SellerFinancePage> {
  late Future<_FinanceData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FinanceData> _load() async {
    final repo = ref.read(sellerRepositoryProvider);

    if (repo == null) {
      throw StateError('Service vendeur indisponible.');
    }

    final sellerId = await repo.sellerId();

    if (sellerId == null) {
      throw StateError('Aucun vendeur associé à ce compte.');
    }

    final client = repo.client;

    final ledgerRows = await client
        .from('seller_ledger')
        .select(
          'id,order_group_id,entry_type,amount,currency,reference_id,created_at',
        )
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .limit(200);

    final commissionRows = await client
        .from('commissions')
        .select(
          'id,order_group_id,rate,base_amount,commission_amount,currency,status,created_at',
        )
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .limit(200);

    final payoutRows = await client
        .from('seller_payouts')
        .select(
          'id,amount,currency,provider,provider_reference,status,requested_at,paid_at',
        )
        .eq('seller_id', sellerId)
        .order('requested_at', ascending: false)
        .limit(100);

    return _FinanceData(
      ledger: (ledgerRows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      commissions: (commissionRows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      payouts: (payoutRows as List)
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
      body: FutureBuilder<_FinanceData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur finance : ' + snapshot.error.toString(),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();

          final ledgerBalance = data.ledger.fold<num>(
            0,
            (sum, item) =>
                sum +
                (num.tryParse(item['amount']?.toString() ?? '') ?? 0),
          );

          final totalCommission = data.commissions.fold<num>(
            0,
            (sum, item) =>
                sum +
                (num.tryParse(
                      item['commission_amount']?.toString() ?? '',
                    ) ??
                    0),
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _FinanceCard(
                  title: 'Solde du ledger',
                  value: ledgerBalance.toStringAsFixed(0) + ' XOF',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _FinanceCard(
                  title: 'Commissions cumulées',
                  value: totalCommission.toStringAsFixed(0) + ' XOF',
                  icon: Icons.percent_outlined,
                ),
                const SizedBox(height: 16),
                Text(
                  'Mouvements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final item in data.ledger)
                  Card(
                    child: ListTile(
                      title: Text(
                        item['entry_type']?.toString() ?? 'Mouvement',
                      ),
                      subtitle: Text(
                        item['created_at']?.toString() ?? '',
                      ),
                      trailing: Text(
                        (item['amount']?.toString() ?? '0') +
                            ' ' +
                            (item['currency']?.toString() ?? 'XOF'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Commissions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final item in data.commissions)
                  Card(
                    child: ListTile(
                      title: Text(
                        (item['rate']?.toString() ?? '0') + ' %',
                      ),
                      subtitle: Text(
                        'Base : ' +
                            (item['base_amount']?.toString() ?? '0') +
                            ' XOF • ' +
                            (item['status']?.toString() ?? '-'),
                      ),
                      trailing: Text(
                        (item['commission_amount']?.toString() ?? '0') +
                            ' XOF',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Retraits',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final item in data.payouts)
                  Card(
                    child: ListTile(
                      title: Text(
                        (item['amount']?.toString() ?? '0') +
                            ' XOF',
                      ),
                      subtitle: Text(
                        (item['provider']?.toString() ?? '-') +
                            ' • ' +
                            (item['status']?.toString() ?? '-'),
                      ),
                      trailing: Text(
                        item['requested_at']?.toString() ?? '',
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _FinanceData {
  const _FinanceData({
    required this.ledger,
    required this.commissions,
    required this.payouts,
  });

  final List<Map<String, dynamic>> ledger;
  final List<Map<String, dynamic>> commissions;
  final List<Map<String, dynamic>> payouts;
}
