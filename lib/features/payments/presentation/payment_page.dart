import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String provider = 'CINETPAY';
  bool loading = false;
  late Future<Map<String, dynamic>?> orderFuture;
  String? paymentIntentId;
  String? checkoutUrl;

  @override
  void initState() {
    super.initState();
    orderFuture = _loadOrder();
  }

  Future<Map<String, dynamic>?> _loadOrder() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('orders')
        .select('id,status,total,currency')
        .eq('id', widget.orderId)
        .eq('customer_id', user.id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> preparePayment(Map<String, dynamic> order) async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;
    if (order['status']?.toString() != 'PENDING_PAYMENT') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette commande n’attend plus de paiement.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final repository = PaymentRepository(client);
      final session = await repository.createPaymentSession(
        orderId: widget.orderId,
        provider: provider,
      );
      final url = Uri.tryParse(session['checkout_url']?.toString() ?? '');
      final paymentId = session['payment_id']?.toString();
      if (url == null || url.scheme != 'https' || url.host.isEmpty) {
        throw StateError('Lien de paiement invalide.');
      }
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Impossible d’ouvrir le paiement.');
      }
      if (!mounted) return;
      setState(() {
        paymentIntentId = paymentId;
        checkoutUrl = url.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement ouvert dans le navigateur.')),
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
      body: FutureBuilder<Map<String, dynamic>?>( 
        future: orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur commande : ${snapshot.error}'));
          }
          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Commande introuvable.'));
          }
          final total = (order['total'] as num?)?.toDouble() ?? 0;
          final currency = order['currency']?.toString() ?? 'XOF';
          final status = order['status']?.toString() ?? '—';
          final canPay = status == 'PENDING_PAYMENT';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text('Commande #${widget.orderId.substring(0, widget.orderId.length > 8 ? 8 : widget.orderId.length)}'),
                  subtitle: Text('Statut : $status'),
                  trailing: Text(
                    '${total.toStringAsFixed(0)} $currency',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: provider,
                decoration: const InputDecoration(
                  labelText: 'Moyen de paiement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'WAVE',
                    child: Text('Wave'),
                  ),
                  DropdownMenuItem(
                    value: 'CINETPAY',
                    child: Text('Orange Money / Moov Money (CinetPay)'),
                  ),
                ],
                onChanged: loading || !canPay
                    ? null
                    : (value) => setState(() => provider = value ?? provider),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading || !canPay
                    ? null
                    : () => preparePayment(order),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Préparer le paiement'),
              ),
              if (paymentIntentId != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.pending_actions_outlined),
                    title: const Text('Paiement lancé'),
                    subtitle: Text(
                      checkoutUrl == null
                          ? 'Référence interne : $paymentIntentId'
                          : 'Le checkout fournisseur a été ouvert.',
                    ),
                  ),
                ),
              ],
              if (!canPay)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Le paiement mobile sera accessible lorsque la commande sera en attente de paiement.',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}