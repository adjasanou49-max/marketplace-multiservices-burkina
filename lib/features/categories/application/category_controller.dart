import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../domain/category.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  if (repository == null) return const [];
  return repository.fetchActive();
});
