import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class AdminAccountsPage extends ConsumerStatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  ConsumerState<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends ConsumerState<AdminAccountsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
    search.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    if (client?.auth.currentUser == null) {
      throw StateError('Authentification requise.');
    }
    final rows = await client!
        .from('profiles')
        .select('id,first_name,last_name,display_name,phone,status,verification_status,created_at')
        .order('created_at', ascending: false)
        .limit(500);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> _setStatus(
    Map<String, dynamic> user,
    String status,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Passer le compte en $status'),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motif',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              reasonController.text.trim(),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;

    try {
      final client = ref.read(supabaseProvider);
      await client?.rpc(
        'admin_set_account_status',
        params: {
          'p_user_id': user['id'],
          'p_status': status,
          'p_reason': reason,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compte mis à jour : $status')),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modification refusée : ' + error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des comptes'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Rechercher un utilisateur',
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ' + snapshot.error.toString()));
                }

                final rows = (snapshot.data ?? const <Map<String, dynamic>>[])
                    .where((row) {
                  if (query.isEmpty) return true;
                  final text = [
                    row['display_name'],
                    row['first_name'],
                    row['last_name'],
                    row['phone'],
                    row['id'],
                  ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
                  return text.contains(query);
                }).toList();

                if (rows.isEmpty) {
                  return const Center(child: Text('Aucun compte trouvé.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final user = rows[index];
                    final current = user['status']?.toString() ?? 'ACTIVE';
                    final display = user['display_name']?.toString().trim();
                    final fallback = [
                      user['first_name']?.toString(),
                      user['last_name']?.toString(),
                    ].where((value) => value != null && value.isNotEmpty).join(' ');
                    final name = (display == null || display.isEmpty)
                        ? (fallback.isEmpty ? user['id'].toString() : fallback)
                        : display;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          current +
                              ' • vérification ' +
                              (user['verification_status']?.toString() ?? '-'),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _setStatus(user, value),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'ACTIVE',
                              child: Text('Réactiver'),
                            ),
                            PopupMenuItem(
                              value: 'SUSPENDED',
                              child: Text('Suspendre'),
                            ),
                            PopupMenuItem(
                              value: 'BLOCKED',
                              child: Text('Bloquer'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
