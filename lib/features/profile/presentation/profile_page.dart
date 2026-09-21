import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {
      user = null;
    }

    final isConnected = user != null;
    final accountSubtitle = user?.email ?? 'Aucun compte connecté';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mon compte'),
            subtitle: Text(accountSubtitle),
            onTap: () {
              if (isConnected) return;
              GoRouter.of(context).push('/auth');
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Mes adresses'),
            onTap: () => GoRouter.of(context).push('/addresses'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Mes commandes'),
            onTap: () => GoRouter.of(context).push('/orders'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Paramètres'),
          ),
          if (isConnected)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () async {
                try {
                  await Supabase.instance.client.auth.signOut();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnexion effectuée.')),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible de terminer la déconnexion.'),
                    ),
                  );
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login_outlined),
              title: const Text('Se connecter'),
              onTap: () => GoRouter.of(context).push('/auth'),
            ),
        ],
      ),
    );
  }
}
