import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/seller_shop_repository.dart';

class SellerCreateShopPage extends ConsumerStatefulWidget {
  const SellerCreateShopPage({super.key});

  @override
  ConsumerState<SellerCreateShopPage> createState() => _SellerCreateShopPageState();
}

class _SellerCreateShopPageState extends ConsumerState<SellerCreateShopPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  List<String> _suggestions(String base) {
    final normalized = base.trim();
    if (normalized.isEmpty) return const [];
    return [
      'Boutique $normalized',
      '$normalized Market',
      '$normalized Express',
      '$normalized Store',
    ].where((name) => name != normalized).toList();
  }

  Future<void> _create() async {
    final name = nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de boutique est trop court.')),
      );
      return;
    }

    final client = ref.read(supabaseProvider);
    if (client == null) return;

    setState(() => loading = true);
    try {
      final id = await SellerShopRepository(client).createShop(
        name: name,
        description: descriptionController.text,
        phone: phoneController.text,
        address: addressController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Boutique créée et envoyée en vérification : $id')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('shop_name_taken')
          ? 'Ce nom de boutique est déjà utilisé. Choisissez une autre proposition.'
          : 'Création impossible : $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions(nameController.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer ma boutique')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Le nom doit être unique. La boutique sera soumise à vérification avant activation.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            enabled: !loading,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nom de la boutique',
              hintText: 'Ex. Faso Market',
              border: OutlineInputBorder(),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Propositions :'),
            Wrap(
              spacing: 8,
              children: [
                for (final suggestion in suggestions.take(4))
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: loading
                        ? null
                        : () => setState(() => nameController.text = suggestion),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: descriptionController,
            enabled: !loading,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneController,
            enabled: !loading,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: addressController,
            enabled: !loading,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: loading ? null : _create,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.store_outlined),
            label: Text(loading ? 'Création…' : 'Créer la boutique'),
          ),
        ],
      ),
    );
  }
}