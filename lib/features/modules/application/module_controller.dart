import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/module_repository.dart';
import '../domain/marketplace_module.dart';

final moduleRepositoryProvider = Provider<ModuleRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : ModuleRepository(client);
});

final enabledModulesProvider =
    FutureProvider<List<MarketplaceModule>>((ref) async {
  final repository = ref.watch(moduleRepositoryProvider);
  if (repository == null) return const [];
  return repository.enabledModules();
});
