import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../addresses/application/address_controller.dart';
import '../../addresses/domain/delivery_address.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/data/cart_repository.dart';
import '../../delivery/data/delivery_quote_repository.dart';
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
  final couponController = TextEditingController();
  late final String idempotencyKey =
      'checkout-${DateTime.now().microsecondsSinceEpoch}';
  CheckoutState state = const CheckoutState();
  bool submitting = false;
  bool quoteLoading = false;
  bool deliveryQuoteValid = false;

  @override
  void dispose() {
    couponController.dispose();
    super.dispose();
  }

  Future<void> _refreshDeliveryQuote(DeliveryAddress address) async {
    final client = ref.read(supabaseProvider);
    final cartItems = ref.read(cartControllerProvider);
    if (client == null || cartItems.isEmpty) {
      return;
    }

    setState(() => quoteLoading = true);
    try {
      final cartRepository = CartRepository(client);
      await cartRepository.syncItems(cartItems);

      final quoteRepository = DeliveryQuoteRepository(client);
      final quote = await quoteRepository.quote(
        cartId: await quoteRepository.activeCartId(),
        deliveryAddress: {
          'id': address.id,
          'recipient_name': address.recipientName,
          'phone': address.phone,
          'address_line': address.addressLine,
          'city': address.city,
          'latitude': address.latitude,
          'longitude': address.longitude,
        },
      );

      if (!mounted) return;
      setState(() {
        state = state.copyWith(
          addressId: address.id,
          deliveryFee: quote.customerFee,
          deliveryDistanceKm: quote.distanceKm,
          deliveryStopCount: quote.stopCount,
        );
        deliveryQuoteValid = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        state = state.copyWith(
          deliveryFee: 0,
          clearDeliveryDistanceKm: true,
          deliveryStopCount: 0,
        );
        deliveryQuoteValid = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Frais de livraison indisponibles : $error')),
      );
    } finally {
      if (mounted) setState(() => quoteLoading = false);
    }
  }
  Future<void> submit() async {
    final items = ref.read(cartControllerProvider);
    final repository = ref.read(orderRepositoryProvider);
    final addressId = state.addressId;

    if (items.isEmpty || repository == null || addressId == null || quoteLoading || !deliveryQuoteValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculez d’abord les frais de livraison.'),
        ),
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
        couponCode: couponController.text.trim().isEmpty
            ? null
            : couponController.text.trim(),
        idempotencyKey: idempotencyKey,
      );

      final orderId = await repository.createOrder(draft);
      if (!mounted) return;

      ref.read(cartControllerProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commande créée : $orderId')),
      );
      context.push('/payment/$orderId');
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
                final selectedAddress = items.firstWhere(
                  (item) => item.id == selected,
                );
                setState(
                  () => state = state.copyWith(addressId: selected),
                );
                _refreshDeliveryQuote(selectedAddress);
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
                          final selectedAddress = items.firstWhere(
                            (item) => item.id == value,
                          );
                          setState(() {
                            state = state.copyWith(addressId: value);
                            deliveryQuoteValid = false;
                          });
                          _refreshDeliveryQuote(selectedAddress);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: couponController,
                enabled: !submitting,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code promo (optionnel)',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text('Sous-total : ${subtotal.toStringAsFixed(0)} XOF'),
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quoteLoading
                          ? 'Calcul des frais de livraison...'
                          : 'Livraison : ${state.deliveryFee.toStringAsFixed(0)} XOF',
                    ),
                  ),
                ],
              ),
              if (!quoteLoading && state.deliveryDistanceKm != null)
                Text(
                  '${state.deliveryStopCount} point(s) vendeur • '
                  '${state.deliveryDistanceKm!.toStringAsFixed(1)} km max',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const Divider(),
              Text(
                'Total : ${total.toStringAsFixed(0)} XOF',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submitting || quoteLoading || !deliveryQuoteValid
                    ? null
                    : submit,
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
