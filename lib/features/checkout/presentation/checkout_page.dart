import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cart/application/cart_controller.dart';
import '../domain/checkout_state.dart';
import '../../orders/domain/order_draft.dart';
import '../../orders/data/order_repository.dart';
import '../../../core/providers/repository_providers.dart';

final orderRepositoryProvider = Provider<OrderRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : OrderRepository(client);
});

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});
  @override ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final addressController = TextEditingController();
  final noteController = TextEditingController();
  CheckoutState state = const CheckoutState();

  @override
  void dispose() {
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final items = ref.read(cartControllerProvider);
    final repository = ref.read(orderRepositoryProvider);
    if (items.isEmpty || repository == null) return;
    final addressId = addressController.text.trim();
    if (addressId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse de livraison requise')));
      return;
    }
    final subtotal = ref.read(cartTotalProvider);
    final draft = OrderDraft(
      items: items, addressId: addressId, subtotal: subtotal,
      deliveryFee: state.deliveryFee,
      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
    );
    try {
      final orderId = await repository.createOrder(draft);
      if (!mounted) return;
      ref.read(cartControllerProvider.notifier).remove(items.first.productId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commande créée : $orderId')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur commande : $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartTotalProvider);
    final total = subtotal + state.deliveryFee;
    return Scaffold(
      appBar: AppBar(title: const Text('Validation de commande')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: addressController, decoration: const InputDecoration(labelText: 'ID adresse de livraison')),
        const SizedBox(height: 12),
        TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Note (optionnel)')),
        const SizedBox(height: 24),
        Text('Sous-total : \${subtotal.toStringAsFixed(0)} XOF'),
        Text('Livraison : \${state.deliveryFee.toStringAsFixed(0)} XOF'),
        const Divider(),
        Text('Total : \${total.toStringAsFixed(0)} XOF', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        FilledButton(onPressed: submit, child: const Text('Créer la commande')),
      ]),
    );
  }
}
