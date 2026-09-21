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
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            onPressed: () => GoRouter.of(context).push('/admin/modules'),
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Modules',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: AdminDashboardRepository(client).counts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Accès refusé ou erreur : ${snapshot.error}'),
            );
          }

          final counts = snapshot.data ?? const <String, int>{};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: counts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (_, index) {
                  final entry = counts.entries.elementAt(index);
                  return Card(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value.toString(),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(entry.key, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.extension_outlined),
                  title: const Text('Gérer les modules'),
                  subtitle: const Text(
                    'Activer ou désactiver les services visibles dans l’application.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => GoRouter.of(context).push('/admin/modules'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}