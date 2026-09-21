import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/checkout/presentation/checkout_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/addresses/presentation/addresses_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
    GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
    GoRoute(path: '/checkout', builder: (context, state) => const CheckoutPage()),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersPage()),
    GoRoute(path: '/addresses', builder: (context, state) => const AddressesPage()),
  ],
);