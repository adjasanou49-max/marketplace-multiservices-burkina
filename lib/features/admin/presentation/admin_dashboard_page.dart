import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/admin_dashboard_repository.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: AdminDashboardRepository(client).counts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Accès refusé ou erreur : ${snapshot.error}'));
          }
          final counts = snapshot.data ?? const <String, dynamic>{};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: counts.entries
                    .map(
                      (entry) => Card(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.value.toString(),
                                style: Theme.of(context)
                                    .textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(entry.key),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Outils de gestion',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Modules de la plateforme'),
                  subtitle: const Text('Activer ou désactiver les services'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => GoRouter.of(context).push('/admin/modules'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text('Tarification livraison'),
                  subtitle: const Text('Configurer les frais par distance'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      GoRouter.of(context).push('/admin/delivery-pricing'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Comptes'),
                  subtitle: const Text('Suspendre, bloquer ou réactiver'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      GoRouter.of(context).push('/admin/accounts'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Produits'),
                  subtitle: const Text('Modérer le catalogue'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      GoRouter.of(context).push('/admin/products'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.currency_exchange_outlined),
                  title: const Text('Remboursements'),
                  subtitle: const Text('Examiner et traiter les demandes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      GoRouter.of(context).push('/admin/refunds'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}