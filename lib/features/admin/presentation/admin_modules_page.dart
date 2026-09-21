import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/admin_module_repository.dart';

class AdminModulesPage extends ConsumerStatefulWidget {
  const AdminModulesPage({super.key});

  @override
  ConsumerState<AdminModulesPage> createState() => _AdminModulesPageState();
}

class _AdminModulesPageState extends ConsumerState<AdminModulesPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return const [];
    return AdminModuleRepository(client).all();
  }

  Future<void> _toggle(
    BuildContext context,
    Map<String, dynamic> module,
    bool enabled,
  ) async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await AdminModuleRepository(client).setEnabled(
        module['key']?.toString() ?? '',
        enabled,
      );
      if (mounted) {
        setState(() => future = _load());
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Modules de la plateforme')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const Center(child: Text('Aucun module configuré'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final module = rows[index];
              final enabled = module['enabled'] == true;
              return SwitchListTile(
                title: Text(
                  module['label']?.toString() ??
                      module['key']?.toString() ?? 'Module',
                ),
                subtitle: Text(module['route']?.toString() ?? ''),
                value: enabled,
                onChanged: (value) => _toggle(context, module, value),
              );
            },
          );
        },
      ),
    );
  }
}