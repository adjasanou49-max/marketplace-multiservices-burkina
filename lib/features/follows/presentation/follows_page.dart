import 'package:flutter/material.dart';

class FollowsPage extends StatelessWidget {
  const FollowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivis')),
      body: const Center(child: Text('Vos boutiques et produits suivis apparaîtront ici.')),
    );
  }
}
