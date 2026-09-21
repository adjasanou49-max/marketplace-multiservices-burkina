import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/follows_repository.dart';

final followsRepositoryProvider = Provider<FollowsRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : FollowsRepository(client);
});

class FollowsPage extends ConsumerStatefulWidget {
  const FollowsPage({super.key});

  @override
  ConsumerState<FollowsPage> createState() => _FollowsPageState();
}

class _FollowsPageState extends ConsumerState<FollowsPage> {
  int _tab = 0;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    final repo = ref.read(followsRepositoryProvider);

    if (repo == null) return Future.value(const []);

    return _tab == 0
        ? repo.favoriteProducts()
        : repo.followedShops();
  }

  void _changeTab(int tab) {
    setState(() {
      _tab = tab;
      _future = _load();
    });
  }

  Future<void> _removeProduct(String id) async {
    final repo = ref.read(followsRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.toggleProductFavorite(id);
      if (!mounted) return;
      setState(() => _future = _load());
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _removeShop(String id) async {
    final repo = ref.read(followsRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.toggleShopFollow(id);
      if (!mounted) return;
      setState(() => _future = _load());
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opération impossible : ' + error.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(supabaseProvider)?.auth.currentUser != null;

    if (!signedIn) {
      return const Scaffold(
        body: Center(
          child: Text('Connectez-vous pour voir vos favoris et suivis.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes suivis'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.favorite_outline),
                  label: Text('Favoris'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.storefront_outlined),
                  label: Text('Boutiques'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) {
                if (value.isNotEmpty) _changeTab(value.first);
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur : ' + snapshot.error.toString(),
                    ),
                  );
                }

                final items =
                    snapshot.data ?? const <Map<String, dynamic>>[];

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      _tab == 0
                          ? 'Aucun produit favori.'
                          : 'Aucune boutique suivie.',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _load());
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];

                      if (_tab == 0) {
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.favorite),
                            ),
                            title: Text(
                              item['name']?.toString() ?? 'Produit',
                            ),
                            subtitle: Text(
                              (item['price']?.toString() ?? '0') +
                                  ' ' +
                                  (item['currency']?.toString() ?? 'XOF'),
                            ),
                            trailing: IconButton(
                              onPressed: () => _removeProduct(
                                item['product_id'].toString(),
                              ),
                              icon: const Icon(Icons.favorite),
                            ),
                          ),
                        );
                      }

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.storefront_outlined),
                          ),
                          title: Text(
                            item['name']?.toString() ?? 'Boutique',
                          ),
                          subtitle: Text(
                            item['description']?.toString() ?? '',
                          ),
                          trailing: IconButton(
                            onPressed: () => _removeShop(
                              item['shop_id'].toString(),
                            ),
                            icon: const Icon(Icons.favorite),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
