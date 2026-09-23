import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/shop.dart';

final shopsProvider = FutureProvider<List<Shop>>((ref) async {
  final repository = ref.watch(shopRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchActive();
});


final shopByIdProvider =
    FutureProvider.autoDispose.family<Shop?, String>((ref, id) async {
  final repository = ref.watch(shopRepositoryProvider);
  if (repository == null) return null;
  return repository.fetchActiveById(id);
});
