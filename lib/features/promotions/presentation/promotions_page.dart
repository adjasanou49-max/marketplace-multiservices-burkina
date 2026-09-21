import 'package:flutter/material.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      body: const Center(
        child: Text('Les promotions disponibles apparaîtront ici.'),
      ),
    );
  }
}
