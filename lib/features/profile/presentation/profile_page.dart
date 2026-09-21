import 'package:flutter/material.dart';

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
        ],
      ),
    );
  }
}
