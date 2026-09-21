import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/group_buy_repository.dart';

final groupBuyRepositoryProvider = Provider<GroupBuyRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : GroupBuyRepository(client);
});

class GroupBuyPage extends ConsumerStatefulWidget {
  const GroupBuyPage({super.key});

  @override
  ConsumerState<GroupBuyPage> createState() => _GroupBuyPageState();
}

class _GroupBuyPageState extends ConsumerState<GroupBuyPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final repository = ref.read(groupBuyRepositoryProvider);
    if (repository == null) return const [];
    return repository.active();
  }

  Future<void> _join(Map<String, dynamic> group) async {
    final repository = ref.read(groupBuyRepositoryProvider);
    if (repository == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final memberId = await repository.join(
        groupBuyId: group['id'].toString(),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Participation enregistrée : $memberId')),
      );
      if (mounted) setState(() => future = _load());
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achats groupés')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final groups =
              snapshot.data ?? const <Map<String, dynamic>>[];
          if (groups.isEmpty) {
            return const Center(child: Text('Aucun achat groupé actif.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => future = _load());
              await future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final group = groups[index];
                final target = group['target_quantity'] ?? 0;
                final current = group['current_quantity'] ?? 0;
                return Card(
                  child: ListTile(
                    title: Text(group['title']?.toString() ?? 'Achat groupé'),
                    subtitle: Text(
                      '$current / $target participants • ${group['group_price'] ?? 0} XOF',
                    ),
                    trailing: FilledButton(
                      onPressed: () => _join(group),
                      child: const Text('Rejoindre'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}