import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class PromotionsPage extends ConsumerStatefulWidget {
  const PromotionsPage({super.key});

  @override
  ConsumerState<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends ConsumerState<PromotionsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return const [];

    final rows = await client
        .from('promotions')
        .select('id,shop_id,name,promotion_type,value,starts_at,ends_at')
        .eq('active', true)
        .lte('starts_at', DateTime.now().toUtc().toIso8601String())
        .gte('ends_at', DateTime.now().toUtc().toIso8601String())
        .order('ends_at')
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur : ' + snapshot.error.toString()),
            );
          }

          final promotions =
              snapshot.data ?? const <Map<String, dynamic>>[];
          if (promotions.isEmpty) {
            return const Center(
              child: Text('Aucune promotion active actuellement.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: promotions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final item = promotions[index];
              final type = item['promotion_type']?.toString() ?? 'OFFRE';
              final value = item['value']?.toString() ?? '0';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_offer_outlined),
                  ),
                  title: Text(item['name']?.toString() ?? 'Promotion'),
                  subtitle: Text(
                    type + ' • ' + value + ' • jusqu’au ' +
                        (item['ends_at']?.toString() ?? '-'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
