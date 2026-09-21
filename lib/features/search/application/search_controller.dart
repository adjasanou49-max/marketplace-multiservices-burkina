import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/search_repository.dart';
import '../../products/domain/product.dart';

final searchRepositoryProvider = Provider<SearchRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : SearchRepository(client);
});

final searchProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final repository = ref.watch(searchRepositoryProvider);
  if (repository == null) return const [];
  return repository.search(query);
});
