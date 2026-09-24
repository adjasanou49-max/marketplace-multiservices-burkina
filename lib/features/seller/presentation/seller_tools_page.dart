import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SellerToolsPage extends StatelessWidget {
  const SellerToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus vendeur')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Stock'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push('/seller/stock'),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Finance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push('/seller/finance'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Demandes de paiement'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push('/seller/payouts'),
          ),
          ListTile(
            leading: const Icon(Icons.percent_outlined),
            title: const Text('Commissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push('/seller/commissions'),
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Messages administration'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => GoRouter.of(context).push('/messages'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Paramètres vendeur'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                GoRouter.of(context).push('/seller/settings'),
          ),
        ],
      ),
    );
  }
}