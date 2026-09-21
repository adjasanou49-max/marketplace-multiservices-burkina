import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  const OrderDetailsPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  late Future<_OrderDetails> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_OrderDetails> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('Authentification requise.');
    }

    final order = await client
        .from('orders')
        .select(
          'id,status,subtotal,delivery_fee,discount_total,total,currency,delivery_address,created_at',
        )
        .eq('id', widget.orderId)
        .eq('customer_id', user.id)
        .single();

    final groups = await client
        .from('order_groups')
        .select(
          'id,shop_id,status,subtotal,shops(name),order_items(id,product_id,product_name,quantity,unit_price,total_price)',
        )
        .eq('order_id', widget.orderId)
        .order('created_at');

    final returns = await client
        .from('returns')
        .select('id,order_item_id,reason,status,resolution,created_at')
        .eq('order_id', widget.orderId)
        .order('created_at', ascending: false);

    final disputes = await client
        .from('disputes')
        .select('id,reason,status,resolution,created_at,resolved_at')
        .eq('order_id', widget.orderId)
        .order('created_at', ascending: false);

    return _OrderDetails(
      order: Map<String, dynamic>.from(order),
      groups: (groups as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      returns: (returns as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      disputes: (disputes as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  Future<void> _openDispute() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ouvrir un litige'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Motif',
            hintText: 'Expliquez le problème rencontré...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    try {
      final client = ref.read(supabaseProvider);
      final id = await client?.rpc(
        'open_dispute',
        params: {
          'p_order_id': widget.orderId,
          'p_reason': reason,
          'p_against_user_id': null,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Litige créé : ' + id.toString())),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Litige refusé : ' + error.toString())));
    }
  }

  Future<void> _openReturn(String itemId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demander un retour'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Motif du retour',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    try {
      final client = ref.read(supabaseProvider);
      final id = await client?.rpc(
        'open_return',
        params: {
          'p_order_id': widget.orderId,
          'p_order_item_id': itemId,
          'p_reason': reason,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retour demandé : ' + id.toString())),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Retour refusé : ' + error.toString())));
    }
  }

  Future<void> _review(String productId, String shopId) async {
    final form = await showDialog<_ReviewForm>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );
    if (form == null) return;

    try {
      final client = ref.read(supabaseProvider);
      final id = await client?.rpc(
        'create_review',
        params: {
          'p_product_id': productId,
          'p_shop_id': shopId,
          'p_rating': form.rating,
          'p_body': form.body,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avis envoyé pour modération : ' + id.toString())),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Avis refusé : ' + error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la commande'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_OrderDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erreur : ' + snapshot.error.toString()),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();

          final order = data.order;
          final status = order['status']?.toString() ?? '-';
          final delivered = status == 'DELIVERED';

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_long_outlined),
                  ),
                  title: Text(widget.orderId),
                  subtitle: Text(
                    status + ' • ' + (order['created_at']?.toString() ?? ''),
                  ),
                  trailing: Text(
                    (order['total']?.toString() ?? '0') +
                        ' ' +
                        (order['currency']?.toString() ?? 'XOF'),
                  ),
                ),
              ),
              if ((order['delivery_address'] as dynamic) != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Adresse de livraison'),
                    subtitle: Text(order['delivery_address'].toString()),
                  ),
                ),
              for (final group in data.groups) ...[
                const SizedBox(height: 8),
                Card(
                  child: ExpansionTile(
                    title: Text(
                      group['shops'] is Map
                          ? (group['shops']['name']?.toString() ?? 'Boutique')
                          : 'Boutique',
                    ),
                    subtitle: Text(
                      (group['subtotal']?.toString() ?? '0') + ' XOF',
                    ),
                    children: [
                      ..._items(
                        group: group,
                        delivered: delivered,
                        onReturn: _openReturn,
                        onReview: _review,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (status != 'CANCELLED' &&
                  status != 'REFUNDED' &&
                  status != 'PENDING_PAYMENT')
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/delivery/' + widget.orderId),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Suivre la livraison'),
                ),
              if (delivered) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openDispute,
                  icon: const Icon(Icons.gavel_outlined),
                  label: const Text('Ouvrir un litige'),
                ),
              ],
              if (data.returns.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Retours',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...data.returns.map(
                  (row) => ListTile(
                    leading: const Icon(Icons.assignment_return_outlined),
                    title: Text(row['reason']?.toString() ?? '-'),
                    subtitle: Text(row['status']?.toString() ?? '-'),
                  ),
                ),
              ],
              if (data.disputes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Litiges',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...data.disputes.map(
                  (row) => ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: Text(row['reason']?.toString() ?? '-'),
                    subtitle: Text(row['status']?.toString() ?? '-'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _items({
    required Map<String, dynamic> group,
    required bool delivered,
    required Future<void> Function(String itemId) onReturn,
    required Future<void> Function(String productId, String shopId) onReview,
  }) {
    final raw = group['order_items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList()
        : const <Map<String, dynamic>>[];

    final shopId = group['shop_id']?.toString() ?? '';

    return items.map((item) {
      final itemId = item['id']?.toString() ?? '';
      final productId = item['product_id']?.toString() ?? '';

      return ListTile(
        title: Text(item['product_name']?.toString() ?? 'Article'),
        subtitle: Text(
          'Quantité : ' +
              (item['quantity']?.toString() ?? '0') +
              ' • ' +
              (item['total_price']?.toString() ?? '0') +
              ' XOF',
        ),
        trailing: delivered
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'return' && itemId.isNotEmpty) {
                    onReturn(itemId);
                  } else if (value == 'review' &&
                      productId.isNotEmpty &&
                      shopId.isNotEmpty) {
                    onReview(productId, shopId);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'return',
                    child: Text('Demander un retour'),
                  ),
                  PopupMenuItem(
                    value: 'review',
                    child: Text('Laisser un avis'),
                  ),
                ],
              )
            : null,
      );
    }).toList();
  }
}

class _OrderDetails {
  const _OrderDetails({
    required this.order,
    required this.groups,
    required this.returns,
    required this.disputes,
  });

  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> returns;
  final List<Map<String, dynamic>> disputes;
}

class _ReviewForm {
  const _ReviewForm({required this.rating, required this.body});

  final int rating;
  final String body;
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int rating = 5;
  final body = TextEditingController();

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Votre avis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: rating,
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 étoiles')),
              DropdownMenuItem(value: 4, child: Text('4 étoiles')),
              DropdownMenuItem(value: 3, child: Text('3 étoiles')),
              DropdownMenuItem(value: 2, child: Text('2 étoiles')),
              DropdownMenuItem(value: 1, child: Text('1 étoile')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => rating = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: body,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Commentaire (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ReviewForm(rating: rating, body: body.text.trim()),
          ),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
