import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/address_repository.dart';
import '../domain/delivery_address.dart';

final addressRepositoryProvider = Provider<AddressRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : AddressRepository(client);
});

final addressesProvider = FutureProvider<List<DeliveryAddress>>((ref) async {
  final repo = ref.watch(addressRepositoryProvider);
  if (repo == null) return const [];
  return repo.listMine();
});
