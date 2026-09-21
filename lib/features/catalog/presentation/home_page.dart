import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../modules/presentation/service_module_sliver.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();

  late Future<_CatalogMetadata> _metadataFuture;
  List<Map<String, dynamic>> _products = [];
  String? _selectedTypeId;
  String? _selectedCategoryId;
  int _page = 0;
  bool _loadingProducts = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _metadataFuture = _loadMetadata();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<_CatalogMetadata> _loadMetadata() async {
    final repo = ref.read(catalogRepositoryProvider);

    if (repo == null) {
      return const _CatalogMetadata(types: [], categories: []);
    }

    final results = await Future.wait([
      repo.categoryTypes(),
      repo.categories(),
    ]);

    final types = results[0];
    final categories = results[1];

    if (types.isNotEmpty && _selectedTypeId == null) {
      _selectedTypeId = types.first['id']?.toString();
    }

    await _loadProducts(reset: true);

    return _CatalogMetadata(
      types: types,
      categories: categories,
    );
  }

  Future<void> _loadProducts({required bool reset}) async {
    if (_loadingProducts || (!reset && !_hasMore)) return;

    final repo = ref.read(catalogRepositoryProvider);
    if (repo == null) return;

    if (reset) {
      _page = 0;
      _hasMore = true;
    }

    setState(() => _loadingProducts = true);

    try {
      final rows = await repo.products(
        categoryId: _selectedCategoryId,
        offset: _page * 24,
        limit: 24,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _products = rows;
        } else {
          _products = [..._products, ...rows];
        }

        _hasMore = rows.length == 24;
        if (_hasMore) _page++;
      });
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 700) {
      _loadProducts(reset: false);
    }
  }

  void _selectCategory(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadProducts(reset: true);
  }

  List<Map<String, dynamic>> _visibleCategories(
    _CatalogMetadata metadata,
  ) {
    if (_selectedTypeId == null) return metadata.categories;

    return metadata.categories
        .where(
          (item) => item['category_type_id']?.toString() == _selectedTypeId,
        )
        .toList();
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final cart = ref.read(cartRepositoryProvider);
    final client = ref.read(supabaseProvider);

    if (client == null || cart == null || client.auth.currentUser == null) {
      if (mounted) context.push('/auth');
      return;
    }

    try {
      await cart.addToCart(productId: product['id'].toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit ajouté au panier.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’ajouter le produit : ' + error.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Burkina'),
        actions: [
          IconButton(
            tooltip: 'Panier',
            onPressed: () => context.push('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          IconButton(
            tooltip: 'Compte',
            onPressed: () => context.push('/auth'),
            icon: Icon(
              client?.auth.currentUser == null
                  ? Icons.account_circle_outlined
                  : Icons.account_circle,
            ),
          ),
        ],
      ),
      body: FutureBuilder<_CatalogMetadata>(
        future: _metadataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: 'Impossible de charger le catalogue : ' +
                  snapshot.error.toString(),
              onRetry: () {
                setState(() => _metadataFuture = _loadMetadata());
              },
            );
          }

          final metadata = snapshot.data ??
              const _CatalogMetadata(types: [], categories: []);

          final categories = _visibleCategories(metadata);

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CatalogHeaderDelegate(
                  types: metadata.types,
                  categories: categories,
                  selectedTypeId: _selectedTypeId,
                  selectedCategoryId: _selectedCategoryId,
                  onTypeSelected: (id) {
                    setState(() {
                      _selectedTypeId = id;
                      _selectedCategoryId = null;
                    });
                    _loadProducts(reset: true);
                  },
                  onCategorySelected: _selectCategory,
                ),
              ),
              const ServiceModuleSliver(),
              if (_products.isEmpty && !_loadingProducts)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Aucun produit disponible actuellement.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _products.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        return _ProductCard(
                          product: _products[index],
                          onAdd: () => _addToCart(_products[index]),
                        );
                      },
                      childCount:
                          _products.length + (_loadingProducts ? 1 : 0),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 320,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/services'),
        icon: const Icon(Icons.apps_outlined),
        label: const Text('Services'),
      ),
    );
  }
}

class _CatalogMetadata {
  const _CatalogMetadata({
    required this.types,
    required this.categories,
  });

  final List<Map<String, dynamic>> types;
  final List<Map<String, dynamic>> categories;
}

class _CatalogHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CatalogHeaderDelegate({
    required this.types,
    required this.categories,
    required this.selectedTypeId,
    required this.selectedCategoryId,
    required this.onTypeSelected,
    required this.onCategorySelected,
  });

  final List<Map<String, dynamic>> types;
  final List<Map<String, dynamic>> categories;
  final String? selectedTypeId;
  final String? selectedCategoryId;
  final ValueChanged<String?> onTypeSelected;
  final ValueChanged<String?> onCategorySelected;

  @override
  double get minExtent => 152;

  @override
  double get maxExtent => 152;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          children: [
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final type = types[index];
                  final id = type['id']?.toString();

                  return ChoiceChip(
                    selected: id == selectedTypeId,
                    onSelected: (_) => onTypeSelected(id),
                    label: Text(type['name']?.toString() ?? ''),
                  );
                },
              ),
            ),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final category = categories[index];
                  final id = category['id']?.toString();
                  final selected = id == selectedCategoryId;

                  return InkWell(
                    borderRadius: BorderRadius.circular(42),
                    onTap: () => onCategorySelected(
                      selected ? null : id,
                    ),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            child: Icon(
                              selected
                                  ? Icons.check
                                  : Icons.category_outlined,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['name']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CatalogHeaderDelegate oldDelegate) {
    return oldDelegate.types != types ||
        oldDelegate.categories != categories ||
        oldDelegate.selectedTypeId != selectedTypeId ||
        oldDelegate.selectedCategoryId != selectedCategoryId;
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onAdd,
  });

  final Map<String, dynamic> product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final rawShop = product['shops'];
    final shop = rawShop is Map
        ? Map<String, dynamic>.from(rawShop)
        : const <String, dynamic>{};

    final rawImages = product['product_images'];
    final firstImage =
        rawImages is List &&
                rawImages.isNotEmpty &&
                rawImages.first is Map
            ? Map<String, dynamic>.from(rawImages.first as Map)
            : const <String, dynamic>{};

    final storagePath = firstImage['storage_path']?.toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: storagePath != null && storagePath.startsWith('https://')
                ? Image.network(
                    storagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const _ProductImagePlaceholder(),
                  )
                : const _ProductImagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Text(
              product['name']?.toString() ?? 'Produit',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              (product['price']?.toString() ?? '0') + ' XOF',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shop['name']?.toString() ?? 'Boutique',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Ajouter au panier',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_outlined, size: 54),
    );
  }
}
