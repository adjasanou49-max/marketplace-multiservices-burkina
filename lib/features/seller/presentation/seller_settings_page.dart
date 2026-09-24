import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../data/seller_shop_repository.dart';

class SellerSettingsPage extends ConsumerWidget {
  const SellerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non authentifié')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres vendeur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Compte'),
              subtitle: Text(user.email ?? 'Adresse e-mail non disponible'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile'),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>( 
            future: SellerShopRepository(client).mine(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.store_outlined),
                    title: Text('Boutique'),
                    subtitle: Text('Chargement…'),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('Boutique'),
                    subtitle: Text(
                      'Impossible de charger la boutique : '
                      '${snapshot.error}',
                    ),
                  ),
                );
              }

              final shop = snapshot.data;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.store_outlined),
                  title: Text(
                    shop?['name']?.toString() ?? 'Aucune boutique',
                  ),
                  subtitle: Text(
                    shop?['phone']?.toString() ??
                        'Informations de boutique non disponibles',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              onTap: () async {
                try {
                  await AuthRepository(client).signOut();
                  if (!context.mounted) return;
                  context.go('/auth');
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Déconnexion impossible : $error')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
