import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class AdminRefundsPage extends ConsumerStatefulWidget {
  const AdminRefundsPage({super.key});

  @override
  ConsumerState<AdminRefundsPage> createState() => _AdminRefundsPageState();
}

class _AdminRefundsPageState extends ConsumerState<AdminRefundsPage> {
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

    final rows = await client.rpc('get_admin_refunds');
    if (rows is! List) return const [];
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _approve(String refundId) async {
    await _runAction(
      () async {
        await ref.read(supabaseProvider)?.rpc(
          'admin_approve_refund',
          params: {'p_refund_id': refundId},
        );
      },
      'Demande approuvée.',
    );
  }

  Future<void> _reject(String refundId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refuser le remboursement'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Motif'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    await _runAction(
      () async {
        await ref.read(supabaseProvider)?.rpc(
          'admin_reject_refund',
          params: {
            'p_refund_id': refundId,
            'p_reason': reason.isEmpty ? null : reason,
          },
        );
      },
      'Demande refusée.',
    );
  }

  Future<void> _completeManual(String refundId) async {
    final controller = TextEditingController();
    final reference = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer le remboursement fournisseur'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Référence fournisseur',
            hintText: 'Référence CinetPay / opérateur',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
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
          'admin_complete_manual_refund',
          params: {
            'p_refund_id': refundId,
            'p_provider_reference': reference,
          },
        );
      },
      'Remboursement fournisseur confirmé.',
    );
  }
  Future<void> _execute(String refundId) async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    await _runAction(() async {
      final response = await client.functions.invoke(
        'execute-payment-refund',
        body: {'refund_id': refundId},
      );
      return response.data;
    }, 'Remboursement traité.');
  }

  Future<void> _runAction(
    Future<dynamic> Function() action,
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
        SnackBar(content: Text('Opération refusée : ' + error.toString())),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remboursements'),
        actions: [
          IconButton(
            onPressed: _working ? null : _refresh,
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
            return Center(child: Text('Accès impossible : ' + snapshot.error.toString()));
          }

          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune demande de remboursement.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final row = items[index];
              final status = row['refund_status']?.toString() ?? '-';
              final provider = row['provider']?.toString() ?? '-';
              final amount = row['amount']?.toString() ?? '0';
              final reason = row['reason']?.toString() ?? '';
              final id = row['refund_id']?.toString() ?? '';

              return Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    child: Icon(
                      status == 'COMPLETED'
                          ? Icons.check_circle_outline
                          : Icons.currency_exchange_outlined,
                    ),
                  ),
                  title: Text(
                    (row['customer_name']?.toString() ?? 'Client') +
                        ' • ' +
                        amount +
                        ' ' +
                        (row['currency']?.toString() ?? 'XOF'),
                  ),
                  subtitle: Text(
                    'Statut : ' +
                        status +
                        ' • Fournisseur : ' +
                        provider +
                        '\n' +
                        reason,
                  ),
                  trailing: PopupMenuButton<String>(
                    enabled: !_working && id.isNotEmpty,
                    onSelected: (value) {
                      if (value == 'approve') _approve(id);
                      if (value == 'reject') _reject(id);
                      if (value == 'execute') _execute(id);
                      if (value == 'manual_complete') _completeManual(id);
                    },
                    itemBuilder: (_) => [
                      if (status == 'REQUESTED')
                        const PopupMenuItem(
                          value: 'approve',
                          child: Text('Approuver'),
                        ),
                      if (status == 'REQUESTED' || status == 'APPROVED')
                        const PopupMenuItem(
                          value: 'reject',
                          child: Text('Refuser'),
                        ),
                      if (status == 'APPROVED' || status == 'FAILED' || status == 'PROCESSING')
                        const PopupMenuItem(
                          value: 'execute',
                          child: Text('Exécuter'),
                        ),
                      if (provider == 'CINETPAY' &&
                          (status == 'APPROVED' ||
                              status == 'PROCESSING' ||
                              status == 'FAILED'))
                        const PopupMenuItem(
                          value: 'manual_complete',
                          child: Text('Confirmer remboursement manuel'),
                        ),
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
