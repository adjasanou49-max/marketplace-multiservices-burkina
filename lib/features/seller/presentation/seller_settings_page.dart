import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class SellerSettingsPage extends ConsumerStatefulWidget {
  const SellerSettingsPage({super.key});

  @override
  ConsumerState<SellerSettingsPage> createState() => _SellerSettingsPageState();
}

class _SellerSettingsPageState extends ConsumerState<SellerSettingsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('Authentification requise.');
    }

    final rows = await client
        .from('sellers')
        .select('id,user_id,business_name,business_phone,verification_status,created_at,updated_at')
        .eq('user_id', user.id)
        .limit(1);

    if ((rows as List).isEmpty) {
      throw StateError('Profil vendeur introuvable.');
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<void> _edit(Map<String, dynamic> seller) async {
    final name = TextEditingController(
      text: seller['business_name']?.toString() ?? '',
    );
    final phone = TextEditingController(
      text: seller['business_phone']?.toString() ?? '',
    );

    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paramètres vendeur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nom commercial'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone professionnel'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              (name.text.trim(), phone.text.trim()),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    name.dispose();
    phone.dispose();
    if (values == null) return;

    try {
      final client = ref.read(supabaseProvider);
      final id = await client?.rpc(
        'update_seller_profile',
        params: {
          'p_business_name': values.$1,
          'p_business_phone': values.$2,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil vendeur enregistré : ' + id.toString())),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modification refusée : ' + error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres vendeur'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ' + snapshot.error.toString()));
          }
          final seller = snapshot.data;
          if (seller == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Validation du compte vendeur'),
                  subtitle: Text(
                    seller['verification_status']?.toString() ?? '-',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.business_outlined),
                title: const Text('Nom commercial'),
                subtitle: Text(
                  seller['business_name']?.toString() ?? 'Non renseigné',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Téléphone professionnel'),
                subtitle: Text(
                  seller['business_phone']?.toString() ?? 'Non renseigné',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _edit(seller),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier le profil'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Le statut de vérification reste contrôlé par l’administration. Le vendeur ne peut pas le modifier depuis l’application.',
              ),
            ],
          );
        },
      ),
    );
  }
}
