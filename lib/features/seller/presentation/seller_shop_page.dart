import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class SellerShopPage extends ConsumerStatefulWidget {
  const SellerShopPage({super.key});

  @override
  ConsumerState<SellerShopPage> createState() => _SellerShopPageState();
}

class _SellerShopPageState extends ConsumerState<SellerShopPage> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('Authentification requise.');
    }

    final sellers = await client
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if ((sellers as List).isEmpty) {
      throw StateError('Profil vendeur introuvable.');
    }

    final sellerId = (sellers.first as Map)['id'].toString();
    final rows = await client
        .from('shops')
        .select(
          'id,name,description,phone,address,logo_url,cover_url,status,verification_status,created_at,updated_at',
        )
        .eq('seller_id', sellerId)
        .order('created_at')
        .limit(1);

    if ((rows as List).isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<void> _edit(Map<String, dynamic>? current) async {
    final form = await showDialog<_ShopForm>(
      context: context,
      builder: (_) => _ShopDialog(current: current),
    );
    if (form == null) return;

    final client = ref.read(supabaseProvider);
    if (client == null) return;

    try {
      final dynamic result;
      if (current == null) {
        result = await client.rpc(
          'create_seller_shop',
          params: {
            'p_name': form.name,
            'p_description': form.description,
            'p_phone': form.phone,
            'p_address': form.address,
            'p_logo_url': form.logoUrl,
            'p_cover_url': form.coverUrl,
          },
        );
      } else {
        result = await client.rpc(
          'update_seller_shop',
          params: {
            'p_shop_id': current['id'],
            'p_name': form.name,
            'p_description': form.description,
            'p_phone': form.phone,
            'p_address': form.address,
            'p_logo_url': form.logoUrl,
            'p_cover_url': form.coverUrl,
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Boutique enregistrée : ' + result.toString())),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement refusé : ' + error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma boutique'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chargement impossible : ' + snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final shop = snapshot.data;
          if (shop == null) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => _edit(null),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Créer ma boutique'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.storefront_outlined),
                  ),
                  title: Text(shop['name']?.toString() ?? 'Boutique'),
                  subtitle: Text(
                    'Statut : ' +
                        (shop['status']?.toString() ?? '-') +
                        '\nValidation : ' +
                        (shop['verification_status']?.toString() ?? '-'),
                  ),
                ),
              ),
              ListTile(
                title: const Text('Description'),
                subtitle: Text(
                  shop['description']?.toString() ?? 'Non renseignée',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(shop['phone']?.toString() ?? 'Non renseigné'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(shop['address']?.toString() ?? 'Non renseignée'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _edit(shop),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier la boutique'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Après une modification, la boutique repasse en validation afin de protéger les clients contre une modification non contrôlée.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopForm {
  const _ShopForm({
    required this.name,
    required this.description,
    required this.phone,
    required this.address,
    required this.logoUrl,
    required this.coverUrl,
  });

  final String name;
  final String description;
  final String phone;
  final String address;
  final String logoUrl;
  final String coverUrl;
}

class _ShopDialog extends StatefulWidget {
  const _ShopDialog({this.current});

  final Map<String, dynamic>? current;

  @override
  State<_ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<_ShopDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _logo;
  late final TextEditingController _cover;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _name = TextEditingController(text: c?['name']?.toString() ?? '');
    _description =
        TextEditingController(text: c?['description']?.toString() ?? '');
    _phone = TextEditingController(text: c?['phone']?.toString() ?? '');
    _address = TextEditingController(text: c?['address']?.toString() ?? '');
    _logo = TextEditingController(text: c?['logo_url']?.toString() ?? '');
    _cover = TextEditingController(text: c?['cover_url']?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _phone.dispose();
    _address.dispose();
    _logo.dispose();
    _cover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.current == null ? 'Créer ma boutique' : 'Modifier ma boutique',
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom unique de la boutique',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _logo,
              decoration: const InputDecoration(labelText: 'URL du logo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cover,
              decoration: const InputDecoration(labelText: 'URL de couverture'),
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
            final name = _name.text.trim();
            if (name.length < 2) return;
            Navigator.pop(
              context,
              _ShopForm(
                name: name,
                description: _description.text.trim(),
                phone: _phone.text.trim(),
                address: _address.text.trim(),
                logoUrl: _logo.text.trim(),
                coverUrl: _cover.text.trim(),
              ),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
