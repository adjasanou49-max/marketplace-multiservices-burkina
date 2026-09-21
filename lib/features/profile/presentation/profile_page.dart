import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Mon profil'),
          ),
          ListTile(
            leading: Icon(Icons.login_outlined),
            title: Text('Connexion / compte'),
            onTap: () => GoRouter.of(context).push('/auth'),
          ),
          ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text('Mes adresses'),
          ),
          ListTile(
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('Mes commandes'),
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Paramètres'),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Déconnexion'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Déconnexion effectuée.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
