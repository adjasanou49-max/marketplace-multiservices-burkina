import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/checkout_repository.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({
    super.key,
    required this.cartId,
  });

  final String cartId;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  late Future<List<Map<String, dynamic>>> _addressesFuture;
  String? _selectedAddressId;
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _quote;
  String _paymentProvider = 'ORANGE_MONEY';
  bool _loading = false;

  late final String _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _idempotencyKey =
        'checkout-' +
        DateTime.now().toUtc().microsecondsSinceEpoch.toString();

    _addressesFuture = _loadAddresses();
  }

  Future<List<Map<String, dynamic>>> _loadAddresses() async {
    final repo = ref.read(checkoutRepositoryProvider);
    if (repo == null) return const [];

    final rows = await repo.addresses();

    if (rows.isNotEmpty && _selectedAddressId == null) {
      final first = rows.first;
      _selectedAddressId = first['id']?.toString();
      _selectedAddress = first;
      _quote = await _calculateQuote(first);
    }

    return rows;
  }

  Future<Map<String, dynamic>> _calculateQuote(
    Map<String, dynamic> address,
  ) {
    final repo = ref.read(checkoutRepositoryProvider);
    if (repo == null) {
      return Future.error(StateError('Service indisponible.'));
    }

    return repo.calculateDeliveryFee(
      cartId: widget.cartId,
      address: address,
    );
  }

  Future<void> _selectAddress(Map<String, dynamic> address) async {
    setState(() {
      _selectedAddressId = address['id']?.toString();
      _selectedAddress = address;
      _quote = null;
    });

    try {
      final quote = await _calculateQuote(address);
      if (!mounted) return;
      setState(() => _quote = quote);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de calculer la livraison : ' +
                error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _addAddress() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddressDialog(),
    );

    if (result == null) return;

    final repo = ref.read(checkoutRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.createAddress(
        label: result['label']?.toString(),
        recipientName: result['recipient_name'].toString(),
        phone: result['phone']?.toString(),
        addressLine: result['address_line']?.toString(),
        city: result['city']?.toString(),
        latitude: double.tryParse(result['latitude']?.toString() ?? ''),
        longitude: double.tryParse(result['longitude']?.toString() ?? ''),
      );

      if (!mounted) return;
      setState(() => _addressesFuture = _loadAddresses());
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Création de l’adresse impossible : ' +
                error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _checkout() async {
    final repo = ref.read(checkoutRepositoryProvider);
    final addressId = _selectedAddressId;

    if (repo == null || addressId == null || _quote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sélectionnez une adresse et calculez la livraison.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final fee =
          num.tryParse(_quote!['customer_fee']?.toString() ?? '') ?? 0;

      final orderId = await repo.checkout(
        cartId: widget.cartId,
        addressId: addressId,
        deliveryFee: fee,
        idempotencyKey: _idempotencyKey,
      );

      final paymentId = await repo.createPaymentIntent(
        orderId: orderId,
        provider: _paymentProvider,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Commande créée'),
          content: Text(
            'Commande : ' +
                orderId +
                '\nIntention de paiement : ' +
                paymentId,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push('/payment/' + paymentId);
              },
              child: const Text('Voir le paiement'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checkout impossible : ' + error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = _selectedAddress;
    final fee = _quote?['customer_fee']?.toString();
    final distance = _quote?['distance_km']?.toString();
    final stops = _quote?['stop_count']?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Finaliser la commande')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur des adresses : ' +
                    snapshot.error.toString(),
              ),
            );
          }

          final addresses =
              snapshot.data ?? const <Map<String, dynamic>>[];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adresse de livraison',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: _addAddress,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              if (addresses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aucune adresse enregistrée. Ajoutez une adresse pour continuer.',
                    ),
                  ),
                )
              else
                ...addresses.map(
                  (item) => Card(
                    child: RadioListTile<String>(
                      value: item['id'].toString(),
                      groupValue: _selectedAddressId,
                      onChanged: (_) => _selectAddress(item),
                      title: Text(
                        item['label']?.toString() ??
                            item['recipient_name']?.toString() ??
                            'Adresse',
                      ),
                      subtitle: Text(
                        (item['recipient_name']?.toString() ?? '') +
                            '\n' +
                            (item['address_line']?.toString() ?? '') +
                            (item['city']?.toString().isEmpty == true
                                ? ''
                                : ' — ' +
                                    (item['city']?.toString() ?? '')),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'Livraison',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(
                    fee == null ? 'Devis non calculé' : fee + ' XOF',
                  ),
                  subtitle: Text(
                    distance == null
                        ? 'Sélectionnez une adresse'
                        : 'Distance : ' +
                            distance +
                            ' km • ' +
                            (stops ?? '1') +
                            ' point(s)',
                  ),
                  trailing: _quote == null
                      ? const Icon(Icons.calculate_outlined)
                      : const Icon(Icons.check_circle_outline),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Paiement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _paymentProvider,
                decoration: const InputDecoration(
                  labelText: 'Opérateur',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ORANGE_MONEY',
                    child: Text('Orange Money'),
                  ),
                  DropdownMenuItem(
                    value: 'WAVE',
                    child: Text('Wave'),
                  ),
                  DropdownMenuItem(
                    value: 'MOOV_MONEY',
                    child: Text('Moov Money'),
                  ),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _paymentProvider = value);
                        }
                      },
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed:
                    _loading || address == null || _quote == null
                        ? null
                        : _checkout,
                icon: const Icon(Icons.lock_outline),
                label: Text(
                  _loading
                      ? 'Traitement…'
                      : 'Créer la commande et le paiement',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog();

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _label = TextEditingController();
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle adresse'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Libellé'),
            ),
            TextField(
              controller: _recipient,
              decoration: const InputDecoration(
                labelText: 'Nom du destinataire',
              ),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville'),
            ),
            TextField(
              controller: _latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude (optionnel)',
              ),
            ),
            TextField(
              controller: _longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude (optionnel)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final recipient = _recipient.text.trim();
            if (recipient.isEmpty) return;

            Navigator.pop(
              context,
              <String, dynamic>{
                'label': _label.text.trim(),
                'recipient_name': recipient,
                'phone': _phone.text.trim(),
                'address_line': _address.text.trim(),
                'city': _city.text.trim(),
                'latitude': _latitude.text.trim(),
                'longitude': _longitude.text.trim(),
              },
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
