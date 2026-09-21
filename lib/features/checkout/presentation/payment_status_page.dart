import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/repository_providers.dart';

class PaymentStatusPage extends ConsumerStatefulWidget {
  const PaymentStatusPage({
    super.key,
    required this.paymentId,
  });

  final String paymentId;

  @override
  ConsumerState<PaymentStatusPage> createState() =>
      _PaymentStatusPageState();
}

class _PaymentStatusPageState
    extends ConsumerState<PaymentStatusPage> {
  late Future<Map<String, dynamic>?> _future;
  Timer? _timer;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _future = _load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(supabaseProvider);
      if (client == null) return;

      _channel = client
          .channel('payment-' + widget.paymentId)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'payments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: widget.paymentId,
            ),
            callback: (_) {
              if (mounted) setState(() => _future = _load());
            },
          )
          .subscribe();
    });

    _timer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (mounted) setState(() => _future = _load());
      },
    );
  }

  Future<Map<String, dynamic>?> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;

    if (client == null || user == null) return null;

    final rows = await client
        .from('payments')
        .select(
          'id,order_id,provider,amount,currency,status,provider_reference,created_at,updated_at',
        )
        .eq('id', widget.paymentId)
        .limit(1);

    if ((rows as List).isEmpty) return null;

    return Map<String, dynamic>.from(rows.first as Map);
  }

  @override
  void dispose() {
    _timer?.cancel();

    final client = ref.read(supabaseProvider);
    if (_channel != null && client != null) {
      client.removeChannel(_channel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statut du paiement'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur du paiement : ' + snapshot.error.toString(),
              ),
            );
          }

          final payment = snapshot.data;

          if (payment == null) {
            return const Center(
              child: Text('Paiement introuvable.'),
            );
          }

          final status = payment['status']?.toString() ?? 'PENDING';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusLabel(status),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (payment['amount']?.toString() ?? '0') +
                            ' ' +
                            (payment['currency']?.toString() ?? 'XOF') +
                            '\n' +
                            (payment['provider']?.toString() ?? '-'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Paiement : ' + widget.paymentId,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                      if (payment['order_id'] != null) ...[
                        const SizedBox(height: 18),
                        FilledButton.tonal(
                          onPressed: () => context.push(
                            '/delivery/' +
                                payment['order_id'].toString(),
                          ),
                          child: const Text('Suivre la commande'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PROCESSING':
        return 'Paiement en cours';
      case 'SUCCEEDED':
        return 'Paiement réussi';
      case 'FAILED':
        return 'Paiement échoué';
      case 'CANCELLED':
        return 'Paiement annulé';
      case 'REFUNDED':
        return 'Paiement remboursé';
      case 'PARTIALLY_REFUNDED':
        return 'Paiement partiellement remboursé';
      default:
        return 'Paiement en attente';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'SUCCEEDED':
        return Icons.check_circle_outline;
      case 'FAILED':
        return Icons.error_outline;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      case 'REFUNDED':
      case 'PARTIALLY_REFUNDED':
        return Icons.currency_exchange_outlined;
      case 'PROCESSING':
        return Icons.sync_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }
}
