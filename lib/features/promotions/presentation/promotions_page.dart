import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/promotion_repository.dart';

final promotionRepositoryProvider = Provider<PromotionRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : PromotionRepository(client);
});

class PromotionsPage extends ConsumerWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(promotionRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      body: repository == null
          ? const Center(child: Text('Supabase non configuré'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.active(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                final items =
                    snapshot.data ?? const <Map<String, dynamic>>[];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Aucune promotion active actuellement.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final promotion = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.local_offer_outlined),
                        ),
                        title: Text(
                          promotion['name']?.toString() ?? 'Promotion',
                        ),
                        subtitle: Text(
                          '${promotion['promotion_type'] ?? 'OFFRE'} • valeur ${promotion['value'] ?? 0}',
                        ),
                        trailing: SizedBox(
                          width: 120,
                          child: Text(
                            promotion['ends_at']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
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