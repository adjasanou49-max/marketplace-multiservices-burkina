import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_product_repository.dart';

final sellerProductRepositoryProvider = Provider<SellerProductRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : SellerProductRepository(client);
});

class SellerProductsPage extends ConsumerStatefulWidget {
  const SellerProductsPage({super.key, required this.shopId});
  final String shopId;
  @override
  ConsumerState<SellerProductsPage> createState() => _SellerProductsPageState();
}
class _SellerProductsPageState extends ConsumerState<SellerProductsPage> {
  late Future<List<Map<String, dynamic>>> future;
  final Set<String> _updatingProducts = <String>{};
  @override
  void initState() { super.initState(); future = _load(); }
  Future<List<Map<String, dynamic>>> _load() async {
    final repo = ref.read(sellerProductRepositoryProvider);
    if (repo == null) return const [];
    return repo.products(widget.shopId);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mes produits')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (_, s) {
        if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text('Erreur : ${s.error}'));
        final items = s.data ?? const [];
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final p = items[i];
            return ListTile(
              title: Text(p['name'] as String? ?? 'Produit'),
              subtitle: Text('Stock: ${p['inventory'] is Map ? (p['inventory']['quantity'] ?? 0) : 0}'),
              trailing: Switch(
                value: p['status']?.toString() == 'ACTIVE',
                onChanged: (v) async {
                  final repo = ref.read(sellerProductRepositoryProvider);
                  final productId = p['id']?.toString();
                  if (repo == null || productId == null || productId.isEmpty) {
                    return;
                  }
                  if (_updatingProducts.contains(productId)) return;

                  setState(() => _updatingProducts.add(productId));
                  try {
                    await repo.updateActive(productId, v);
                    if (!mounted) return;
                    setState(() => future = _load());
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Modification impossible : $error')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _updatingProducts.remove(productId));
                    }
                  }
                },
              ),
            );
          },
        );
      },
    ),
  );
}