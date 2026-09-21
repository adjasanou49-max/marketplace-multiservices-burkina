import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/cart/presentation/cart_page.dart';
import '../../features/catalog/presentation/home_page.dart';
import '../../features/checkout/presentation/checkout_page.dart';
import '../../features/checkout/presentation/orders_page.dart';
import '../../features/common/presentation/module_placeholder_page.dart';
import '../../features/courier/presentation/courier_page.dart';
import '../../features/delivery/presentation/delivery_tracking_page.dart';
import '../../features/expiry/presentation/expiry_page.dart';
import '../../features/follows/presentation/follows_page.dart';
import '../../features/group_buy/presentation/group_buy_page.dart';
import '../../features/mechanics/presentation/mechanics_page.dart';
import '../../features/messaging/presentation/messages_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/restaurants/presentation/restaurants_page.dart';
import '../../features/seller/presentation/seller_dashboard_page.dart';
import '../../features/seller/presentation/seller_orders_page.dart';
import '../../features/seller/presentation/seller_products_page.dart';
import '../../features/seller/presentation/seller_tools_page.dart';
import '../../features/services/presentation/services_page.dart';
import '../../features/transport/presentation/transport_page.dart';
import '../../features/promotions/presentation/promotions_page.dart';
import '../../features/seller/presentation/seller_finance_page.dart';
import '../../features/seller/presentation/seller_shop_page.dart';
import '../../features/seller/presentation/seller_coupons_page.dart';
import '../../features/verticals/data/vertical_repository.dart';
import '../../features/verticals/presentation/vertical_discovery_page.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/auth', builder: (_, __) => const SignInPage()),
      GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
      GoRoute(
        path: '/checkout/:cartId',
        builder: (_, state) {
          final cartId = state.pathParameters['cartId'];

          if (cartId == null || cartId.isEmpty) {
            return const ModulePlaceholderPage(
              title: 'Panier invalide',
              icon: Icons.shopping_cart_outlined,
            );
          }

          return CheckoutPage(cartId: cartId);
        },
      ),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
      GoRoute(
        path: '/delivery/:orderId',
        builder: (_, state) {
          final orderId = state.pathParameters['orderId'];

          if (orderId == null || orderId.isEmpty) {
            return const ModulePlaceholderPage(
              title: 'Commande invalide',
              icon: Icons.local_shipping_outlined,
            );
          }

          return DeliveryTrackingPage(orderId: orderId);
        },
      ),
      GoRoute(path: '/courier', builder: (_, __) => const CourierPage()),
      GoRoute(
        path: '/restaurants',
        builder: (_, __) => const RestaurantsPage(),
      ),
      GoRoute(
        path: '/transport',
        builder: (_, __) => const TransportPage(),
      ),
      GoRoute(
        path: '/mechanics',
        builder: (_, __) => const MechanicsPage(),
      ),
      GoRoute(
        path: '/expiry',
        builder: (_, __) => const ExpiryPage(),
      ),
      GoRoute(
        path: '/follows',
        builder: (_, __) => const FollowsPage(),
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
        path: '/messages',
        builder: (_, __) => const MessagesPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/seller',
        builder: (_, __) => const SellerToolsPage(),
      ),
      GoRoute(
        path: '/seller/dashboard',
        builder: (_, __) => const SellerDashboardPage(),
      ),
      GoRoute(
        path: '/seller/products',
        builder: (_, __) => const SellerProductsPage(),
      ),
      GoRoute(
        path: '/seller/orders',
        builder: (_, __) => const SellerOrdersPage(),
      ),
      GoRoute(path: '/promotions', builder: (_, __) => const PromotionsPage()),
      GoRoute(path: '/seller/shop', builder: (_, __) => const SellerShopPage()),
      GoRoute(path: '/seller/coupons', builder: (_, __) => const SellerCouponsPage()),
      GoRoute(path: '/seller/finance', builder: (_, __) => const SellerFinancePage()),
      for (final item in const <({String path, VerticalModule module})>[
        (path: '/rides', module: VerticalModule.rides),
        (path: '/rentals', module: VerticalModule.rentals),
        (path: '/real-estate', module: VerticalModule.realEstate),
        (path: '/accommodations', module: VerticalModule.accommodations),
        (path: '/events', module: VerticalModule.events),
        (path: '/jobs', module: VerticalModule.jobs),
        (path: '/professionals', module: VerticalModule.professionals),
        (path: '/agriculture', module: VerticalModule.agriculture),
        (path: '/freight', module: VerticalModule.freight),
        (path: '/health', module: VerticalModule.health),
        (path: '/beauty', module: VerticalModule.beauty),
        (path: '/home-services', module: VerticalModule.homeServices),
        (path: '/digital', module: VerticalModule.digital),
        (path: '/training', module: VerticalModule.training),
        (path: '/creative', module: VerticalModule.creative),
        (path: '/parcels', module: VerticalModule.parcels),
      ])
        GoRoute(
          path: item.path,
          builder: (_, __) => VerticalDiscoveryPage(module: item.module),
        ),
      GoRoute(path: '/seller/stock', builder: (_, __) => const SellerProductsPage()),
      GoRoute(path: '/seller/payouts', builder: (_, __) => const SellerFinancePage()),
      GoRoute(path: '/seller/commissions', builder: (_, __) => const SellerFinancePage()),
      GoRoute(path: '/seller/settings', builder: (_, __) => const SellerToolsPage()),
    ],
  );
});

