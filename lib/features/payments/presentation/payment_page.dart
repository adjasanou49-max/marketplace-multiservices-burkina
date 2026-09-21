import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/payment_repository.dart';
import '../domain/payment_request.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  String provider = 'ORANGE_MONEY';
  bool loading = false;
  String? paymentIntentId;

  Future<void> preparePayment() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    setState(() => loading = true);
    try {
      final repository = PaymentRepository(client);
      final id = await repository.createPending(
        PaymentRequest(
          orderId: widget.orderId,
          provider: provider,
          amount: 0,
        ),
      );
      if (!mounted) return;
      setState(() => paymentIntentId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intention de paiement créée.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur paiement : $error')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Commande : ${widget.orderId}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: provider,
            decoration: const InputDecoration(
              labelText: 'Moyen de paiement',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'ORANGE_MONEY', child: Text('Orange Money')),
              DropdownMenuItem(value: 'WAVE', child: Text('Wave')),
              DropdownMenuItem(value: 'MOOV_MONEY', child: Text('Moov Money')),
            ],
            onChanged: loading ? null : (value) => setState(() => provider = value ?? provider),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : preparePayment,
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Préparer le paiement'),
          ),
          if (paymentIntentId != null) ...[
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.pending_actions_outlined),
                title: const Text('Paiement en attente'),
                subtitle: Text('Référence interne : $paymentIntentId'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}