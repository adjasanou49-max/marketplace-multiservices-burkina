import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../categories/application/category_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_strip.dart';
import '../../products/application/product_controller.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_grid.dart';
import '../../shops/application/shop_controller.dart';
import '../../shops/presentation/shop_card.dart';
import '../../modules/application/module_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  int _selectedCategory = 0;
  bool _programmaticScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 700) {
      ref.read(productsFeedProvider.notifier).loadMore();
    }
    if (_programmaticScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _programmaticScroll) return;
      final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
      if (categories.isEmpty) return;

      var closestIndex = _selectedCategory;
      var closestDistance = double.infinity;

      for (var i = 0; i < categories.length; i++) {
        final context = _sectionKeys[categories[i].id]?.currentContext;
        if (context == null) continue;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;

        final top = box.localToGlobal(Offset.zero).dy;
        final distance = (top - 170).abs();
        if (top <= 210 && distance < closestDistance) {
          closestIndex = i;
          closestDistance = distance;
        }
      }

      if (closestIndex != _selectedCategory) {
        setState(() => _selectedCategory = closestIndex);
      }
    });
  }

  Future<void> _selectCategory(int index, List<Category> categories) async {
    if (index < 0 || index >= categories.length) return;

    final key = _sectionKeys.putIfAbsent(
      categories[index].id,
      GlobalKey.new,
    );
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    setState(() => _selectedCategory = index);
    _programmaticScroll = true;
    try {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    } finally {
      _programmaticScroll = false;
    }
  }

  void _prepareSectionKeys(List<Category> categories) {
    for (final category in categories) {
      _sectionKeys.putIfAbsent(category.id, GlobalKey.new);
    }
  }

  Map<String, List<Product>> _groupProducts(
    List<Category> categories,
    List<Product> products,
  ) {
    final grouped = <String, List<Product>>{
      for (final category in categories) category.id: <Product>[],
    };
    for (final product in products) {
      final categoryId = product.categoryId;
      if (categoryId != null && grouped.containsKey(categoryId)) {
        grouped[categoryId]!.add(product);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final productsState = ref.watch(productsFeedProvider);
    final shopsState = ref.watch(shopsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace Burkina'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            onPressed: () => context.push('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(productsFeedProvider);
          ref.invalidate(shopsProvider);
        },
        child: categoriesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur catégories : $error'),
              ),
            ],
          ),
          data: (categories) => productsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erreur produits : $error'),
                ),
              ],
            ),
            data: (products) {
              _prepareSectionKeys(categories);
              final grouped = _groupProducts(categories, products);

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: TextField(
                        readOnly: true,
                        onTap: () => context.push('/search'),
                        decoration: const InputDecoration(
                          hintText:
                              'Rechercher un produit, une boutique...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: Icon(Icons.tune),
                        ),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CategoryHeaderDelegate(
                      categories: categories,
                      selectedIndex: categories.isEmpty
                          ? 0
                          : _selectedCategory
                                .clamp(0, categories.length - 1)
                                .toInt(),
                      onSelected: (index) =>
                          _selectCategory(index, categories),
                    ),
                  ),
                  const _ServiceModuleSliver(),
                  if (categories.isEmpty)
                    SliverToBoxAdapter(
                      child: ProductGrid(products: products),
                    )
                  else
                    for (final category in categories)
                      SliverToBoxAdapter(
                        key: _sectionKeys[category.id],
                        child: _CategorySection(
                          category: category,
                          products: grouped[category.id] ?? const [],
                        ),
                      ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 4),
                      child: Text(
                        'Boutiques',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: shopsState.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Erreur boutiques : $error'),
                      ),
                      data: (shops) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            for (final shop in shops) ShopCard(shop: shop),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              context.push('/follows');
              break;
            case 3:
              context.push('/messages');
              break;
            case 2:
              context.push('/promotions');
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: 'Suivis',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            label: 'Promos',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.products,
  });

  final Category category;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          products.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Text('Aucun produit disponible dans cette catégorie.'),
                )
              : ProductGrid(products: products),
        ],
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<Category> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  double get minExtent => 104;
  @override
  double get maxExtent => 104;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CategoryStrip(
        categories: categories,
        selectedIndex: selectedIndex,
        onSelected: onSelected,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.categories != categories ||
      oldDelegate.selectedIndex != selectedIndex;
}


class _ServiceModuleSliver extends ConsumerWidget {
  const _ServiceModuleSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(enabledModulesProvider);
    return state.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox(height: 0)),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox(height: 0)),
      data: (modules) {
        final visible = modules
            .where(
              (module) => const <String>{
                '/restaurants',
                '/transport',
                '/mechanics',
                '/expiry',
                '/group-buy',
              }.contains(module.route),
            )
            .toList();

        if (visible.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox(height: 0));
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Text(
                  'Services',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(
                height: 94,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: visible.length,
                  itemBuilder: (_, index) =>
                      _ModuleShortcut(module: visible[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
