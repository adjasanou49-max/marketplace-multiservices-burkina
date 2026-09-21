import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_repository.dart';

final sellerRepositoryProvider = Provider<SellerRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : SellerRepository(client);
});

final sellerDashboardProvider = FutureProvider((ref) async {
  final repo = ref.watch(sellerRepositoryProvider);
  if (repo == null) return const SellerDashboard(shopCount: 0, productCount: 0, pendingOrders: 0, revenue: 0);
  return repo.dashboard();
});