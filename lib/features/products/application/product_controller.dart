import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/product.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchActive();
});

final productsFeedProvider =
    AsyncNotifierProvider.autoDispose<ProductsFeedController, List<Product>>(
  ProductsFeedController.new,
);

class ProductsFeedController extends AutoDisposeAsyncNotifier<List<Product>> {
  static const _pageSize = 24;

  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<Product>> build() async {
    final repository = ref.watch(productRepositoryProvider);
    if (repository == null) {
      _hasMore = false;
      return const [];
    }

    final page = await repository.fetchActivePage(limit: _pageSize);
    _offset = page.length;
    _hasMore = page.length == _pageSize;
    return page;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;

    final repository = ref.read(productRepositoryProvider);
    if (repository == null) {
      _hasMore = false;
      return;
    }

    final current = state.valueOrNull ?? const <Product>[];
    _loadingMore = true;
    try {
      final page = await repository.fetchActivePage(
        limit: _pageSize,
        offset: _offset,
      );

      final ids = current.map((product) => product.id).toSet();
      final uniquePage = [
        for (final product in page)
          if (!ids.contains(product.id)) product,
      ];

      _offset += page.length;
      _hasMore = page.length == _pageSize;

      if (uniquePage.isNotEmpty) {
        state = AsyncData([...current, ...uniquePage]);
      } else if (page.isEmpty) {
        _hasMore = false;
      }
    } catch (error, stackTrace) {
      if (current.isEmpty) {
        state = AsyncError(error, stackTrace);
      }
    } finally {
      _loadingMore = false;
    }
  }
}
