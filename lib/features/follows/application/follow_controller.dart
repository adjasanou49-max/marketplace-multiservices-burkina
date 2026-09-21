import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/follow_repository.dart';

final followRepositoryProvider = Provider<FollowRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : FollowRepository(client);
});

final favoriteProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(followRepositoryProvider);
  if (repository == null) return const [];
  return repository.favoriteProducts();
});

final followedShopsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(followRepositoryProvider);
  if (repository == null) return const [];
  return repository.followedShops();
});