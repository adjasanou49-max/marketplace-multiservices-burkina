import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart_item.dart';

class CartController extends Notifier<List<CartItem>> {
  @override List<CartItem> build() => const [];

  void add(CartItem item) {
    final index = state.indexWhere((entry) => entry.productId == item.productId);
    if (index == -1) { state = [...state, item]; return; }
    final updated = [...state];
    updated[index] = updated[index].copyWith(quantity: updated[index].quantity + item.quantity);
    state = updated;
  }

  void clear() => state = const [];

  void remove(String productId) => state = state.where((item) => item.productId != productId).toList();

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) { remove(productId); return; }
    state = [for (final item in state) item.productId == productId ? item.copyWith(quantity: quantity) : item];
  }

  num get total => state.fold<num>(0, (sum, item) => sum + item.total);
}

final cartControllerProvider = NotifierProvider<CartController, List<CartItem>>(CartController.new);
final cartCountProvider = Provider<int>((ref) => ref.watch(cartControllerProvider).fold<int>(0, (sum, item) => sum + item.quantity));
final cartTotalProvider = Provider<num>((ref) => ref.watch(cartControllerProvider).fold<num>(0, (sum, item) => sum + item.total));
