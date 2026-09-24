import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/user_facing_error.dart';
import '../../../core/providers/repository_providers.dart';

class AdminSellerPayoutsPage extends ConsumerStatefulWidget {
  const AdminSellerPayoutsPage({super.key});

  @override
  ConsumerState<AdminSellerPayoutsPage> createState() =>
      _AdminSellerPayoutsPageState();
}

class _AdminSellerPayoutsPageState
    extends ConsumerState<AdminSellerPayoutsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Authentification requise.');
    }

    final rows = await client
        .from('seller_payouts')
        .select(
          'id,seller_id,amount,currency,provider,provider_reference,status,'
          'requested_at,paid_at,sellers(business_name,business_phone,verification_status)',
        )
        .order('requested_at', ascending: false)
        .limit(200);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> _markPaid(String payoutId) async {
    final controller = TextEditingController();
    final reference = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marquer le reversement comme payé'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Référence fournisseur',
            hintText: 'Référence Wave / Orange Money / Moov Money',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reference == null || reference.isEmpty) return;

    await _runAction(
      () async {
        await ref.read(supabaseProvider)?.rpc(
          'admin_mark_seller_payout_paid',
          params: {
            'p_payout_id': payoutId,
            'p_provider_reference': reference,
          },
        );
      },
      'Reversement marqué comme payé.',
    );
  }

  Future<void> _markFailed(String payoutId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Échec du reversement'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motif',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Déclarer l’échec'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    await _runAction(
      () async {
        await ref.read(supabaseProvider)?.rpc(
          'admin_mark_seller_payout_failed',
          params: {
            'p_payout_id': payoutId,
            'p_reason': reason.isEmpty ? null : reason,
          },
        );
      },
      'Reversement marqué en échec et solde restauré.',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String success,
  ) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(error))),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _sellerName(Map<String, dynamic> row) {
    final seller = row['sellers'];
    if (seller is Map) {
      final name = seller['business_name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'Vendeur ${row['seller_id']?.toString() ?? '—'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reversements vendeurs'),
        actions: [
          IconButton(
            onPressed: _working ? null : () => setState(() => _future = _load()),
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
                'Chargement impossible : ${userFacingError(snapshot.error)}',
              ),
            );
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const Center(child: Text('Aucun reversement.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = rows[index];
              final id = row['id']?.toString() ?? '';
              final amount = row['amount']?.toString() ?? '0';
              final currency = row['currency']?.toString() ?? 'XOF';
              final provider = row['provider']?.toString() ?? '—';
              final status = row['status']?.toString() ?? 'PENDING';
              final reference = row['provider_reference']?.toString();
              final isPending = status == 'PENDING';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sellerName(row),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('$amount $currency • $provider'),
                      const SizedBox(height: 4),
                      Text('Statut : $status'),
                      if (reference != null && reference.isNotEmpty)
                        Text('Référence : $reference'),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _working ? null : () => _markFailed(id),
                                icon: const Icon(Icons.undo),
                                label: const Text('Échec / restituer'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    _working ? null : () => _markPaid(id),
                                icon: const Icon(Icons.check),
                                label: const Text('Marquer payé'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
