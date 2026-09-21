import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../addresses/application/address_controller.dart';
import '../../addresses/domain/delivery_address.dart';
import '../../cart/application/cart_controller.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_draft.dart';
import '../domain/checkout_state.dart';

final orderRepositoryProvider = Provider<OrderRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : OrderRepository(client);
});

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final noteController = TextEditingController();
  CheckoutState state = const CheckoutState();
  bool submitting = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final items = ref.read(cartControllerProvider);
    final repository = ref.read(orderRepositoryProvider);
    final addressId = state.addressId;

    if (items.isEmpty || repository == null || addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une adresse de livraison.')),
      );
      return;
    }

    final subtotal = ref.read(cartTotalProvider);
    setState(() => submitting = true);

    try {
      final draft = OrderDraft(
        items: items,
        addressId: addressId,
        subtotal: subtotal,
        deliveryFee: state.deliveryFee,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      final orderId = await repository.createOrder(draft);
      if (!mounted) return;

      ref.read(cartControllerProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commande créée : $orderId')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur commande : $error')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartTotalProvider);
    final total = subtotal + state.deliveryFee;
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Validation de commande')),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Impossible de charger les adresses : $error'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Ajoutez d’abord une adresse de livraison.'),
            );
          }

          final selected = items.any((item) => item.id == state.addressId)
              ? state.addressId
              : items.first.id;

          if (selected != state.addressId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && state.addressId != selected) {
                setState(
                  () => state = state.copyWith(addressId: selected),
                );
              }
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final address in items)
                    DropdownMenuItem(
                      value: address.id,
                      child: Text(_addressLabel(address)),
                    ),
                ],
                onChanged: submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(
                            () => state = state.copyWith(addressId: value),
                          );
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                enabled: !submitting,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text('Sous-total : ${subtotal.toStringAsFixed(0)} XOF'),
              Text(
                'Livraison : ${state.deliveryFee.toStringAsFixed(0)} XOF',
              ),
              const Divider(),
              Text(
                'Total : ${total.toStringAsFixed(0)} XOF',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Créer la commande'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _addressLabel(DeliveryAddress address) {
    final parts = <String>[
      if ((address.label ?? '').trim().isNotEmpty) address.label!.trim(),
      if ((address.addressLine ?? '').trim().isNotEmpty) (address.addressLine ?? '').trim(),
      if ((address.city ?? '').trim().isNotEmpty) address.city!.trim(),
    ];
    return parts.isEmpty ? address.recipientName : parts.join(' — ');
  }
}
