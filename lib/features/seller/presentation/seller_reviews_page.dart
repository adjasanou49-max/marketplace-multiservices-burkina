import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class SellerReviewsPage extends ConsumerStatefulWidget {
  const SellerReviewsPage({super.key});

  @override
  ConsumerState<SellerReviewsPage> createState() => _SellerReviewsPageState();
}

class _SellerReviewsPageState extends ConsumerState<SellerReviewsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('Authentification requise.');
    }

    final sellers = await client
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    if ((sellers as List).isEmpty) throw StateError('Vendeur introuvable.');

    final sellerId = (sellers.first as Map)['id'].toString();
    final shops = await client
        .from('shops')
        .select('id')
        .eq('seller_id', sellerId);

    final shopIds = (shops as List)
        .map((row) => (row as Map)['id']?.toString())
        .whereType<String>()
        .toList();
    if (shopIds.isEmpty) return const [];

    final rows = await client
        .from('reviews')
        .select(
          'id,rating,body,created_at,product_id,products(name),shop_id',
        )
        .inFilter('shop_id', shopIds)
        .order('created_at', ascending: false)
        .limit(200);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis clients'),
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
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return const Center(child: Text('Aucun avis publié pour vos boutiques.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final row = rows[index];
              final product = row['products'] is Map
                  ? Map<String, dynamic>.from(row['products'] as Map)
                  : const <String, dynamic>{};
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(row['rating']?.toString() ?? '-'),
                  ),
                  title: Text(product['name']?.toString() ?? 'Produit'),
                  subtitle: Text(row['body']?.toString() ?? ''),
                  trailing: Text(row['created_at']?.toString() ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
