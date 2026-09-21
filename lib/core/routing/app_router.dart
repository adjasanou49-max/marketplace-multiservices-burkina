import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/cart/presentation/cart_page.dart';
import '../../features/catalog/presentation/home_page.dart';
import '../../features/common/presentation/module_placeholder_page.dart';
import '../../features/group_buy/presentation/group_buy_page.dart';
import '../../features/services/presentation/services_page.dart';
import '../../features/seller/presentation/seller_tools_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const SignInPage(),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartPage(),
      ),
      GoRoute(
        path: '/group-buy',
        builder: (_, __) => const GroupBuyPage(),
      ),
      GoRoute(
        path: '/services',
        builder: (_, __) => const ServicesPage(),
      ),
      GoRoute(
        path: '/seller',
        builder: (_, __) => const SellerToolsPage(),
      ),
      for (final item in const <Map<String, Object>>[
        {'path': '/restaurants', 'title': 'Restaurants', 'icon': 0},
        {'path': '/transport', 'title': 'Compagnies de transport', 'icon': 1},
        {'path': '/mechanics', 'title': 'Mécaniciens', 'icon': 2},
        {'path': '/expiry', 'title': 'Expiration proche', 'icon': 3},
        {'path': '/promotions', 'title': 'Promotions', 'icon': 4},
        {'path': '/follows', 'title': 'Suivis', 'icon': 5},
        {'path': '/messages', 'title': 'Messages', 'icon': 6},
        {'path': '/seller/stock', 'title': 'Stock vendeur', 'icon': 7},
        {'path': '/seller/finance', 'title': 'Finance vendeur', 'icon': 8},
        {'path': '/seller/payouts', 'title': 'Demandes de paiement', 'icon': 9},
        {'path': '/seller/commissions', 'title': 'Commissions', 'icon': 10},
        {'path': '/seller/settings', 'title': 'Paramètres vendeur', 'icon': 11},
      ])
        GoRoute(
          path: item['path'] as String,
          builder: (_, __) => ModulePlaceholderPage(
            title: item['title'] as String,
            icon: _placeholderIcon(item['icon'] as int),
          ),
        ),
    ],
  );
});

IconData _placeholderIcon(int value) {
  switch (value) {
    case 1:
      return Icons.directions_bus_outlined;
    case 2:
      return Icons.build_outlined;
    case 3:
      return Icons.event_busy_outlined;
    case 4:
      return Icons.local_offer_outlined;
    case 5:
      return Icons.favorite_outline;
    case 6:
      return Icons.chat_outlined;
    case 7:
      return Icons.inventory_2_outlined;
    case 8:
      return Icons.payments_outlined;
    case 9:
      return Icons.account_balance_wallet_outlined;
    case 10:
      return Icons.percent_outlined;
    case 11:
      return Icons.settings_outlined;
    default:
      return Icons.restaurant_outlined;
  }
}
