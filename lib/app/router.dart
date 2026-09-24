import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/home/presentation/home_page.dart';
import '../features/products/domain/product.dart';
import '../features/products/presentation/product_detail_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/checkout/presentation/checkout_page.dart';
import '../features/payments/presentation/payment_page.dart';
import '../features/refunds/presentation/refunds_page.dart';
import '../features/reviews/presentation/review_page.dart';
import '../features/commissions/presentation/commissions_page.dart';
import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/admin/presentation/admin_accounts_page.dart';
import '../features/admin/presentation/admin_products_page.dart';
import '../features/admin/presentation/admin_modules_page.dart';
import '../features/admin/presentation/admin_delivery_pricing_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/addresses/presentation/addresses_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/messaging/presentation/messages_page.dart';
import '../features/messaging/presentation/conversation_page.dart';
import '../features/seller/presentation/seller_orders_page.dart';
import '../features/seller/presentation/seller_order_detail_page.dart';
import '../features/seller/presentation/seller_stock_page.dart';
import '../features/seller/presentation/seller_finance_page.dart';
import '../features/seller/presentation/seller_payouts_page.dart';
import '../features/seller/presentation/seller_settings_page.dart';
import '../features/seller/presentation/seller_navigation.dart';
import '../features/seller/presentation/seller_create_shop_page.dart';
import '../features/promotions/presentation/promotions_page.dart';
import '../features/follows/presentation/follows_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/restaurants/presentation/restaurants_page.dart' show RestaurantsPage;
import '../features/restaurants/presentation/restaurant_detail_page.dart';
import '../features/shops/presentation/shop_detail_page.dart';
import '../features/shops/domain/shop.dart';
import '../features/transport/presentation/transport_page.dart';
import '../features/mechanics/presentation/mechanics_page.dart';
import '../features/courier/presentation/courier_page.dart';
import '../features/delivery/presentation/delivery_tracking_page.dart';
import '../features/services/presentation/services_page.dart';
import '../features/group_buy/presentation/group_buy_page.dart';
import '../features/expiry/presentation/expiry_page.dart';
import '../features/bookings/presentation/bookings_page.dart';
import '../features/verticals/data/vertical_repository.dart';
import '../features/verticals/presentation/vertical_discovery_page.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    try {
      _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (_) => notifyListeners(),
      );
    } catch (_) {
      _subscription = null;
    }
  }

  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

String? _routeGuard(BuildContext context, GoRouterState state) {
  const protectedPrefixes = [
    '/cart',
    '/checkout',
    '/orders',
    '/order',
    '/addresses',
    '/messages',
    '/conversation',
    '/notifications',
    '/follows',
    '/profile',
    '/refunds',
    '/review',
    '/payment',
    '/seller',
    '/admin',
    '/courier',
    '/delivery',
  ];

  bool protected = false;
  for (final prefix in protectedPrefixes) {
    if (state.uri.path == prefix || state.uri.path.startsWith('$prefix/')) {
      protected = true;
      break;
    }
  }

  bool authenticated;
  try {
    authenticated = Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    return protected ? '/auth' : null;
  }

  if (!authenticated && protected) return '/auth';
  if (authenticated && state.uri.path == '/auth') return '/';
  return null;
}

GoRouter createAppRouter() {
  final authRefreshNotifier = _AuthRefreshNotifier();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRefreshNotifier,
  redirect: _routeGuard,
  routes: [
 GoRoute(path:'/',builder:(c,s)=>const HomePage()),
 GoRoute(path:'/search',builder:(c,s)=>const SearchPage()),
 GoRoute(
      path: '/product/:id',
      builder: (c, s) {
        final product = s.extra;
        return product is Product
            ? ProductDetailPage(product: product)
            : ProductDetailPage(productId: s.pathParameters['id']!);
      },
    ),
 GoRoute(path:'/cart',builder:(c,s)=>const CartPage()),
 GoRoute(path:'/checkout',builder:(c,s)=>const CheckoutPage()),
 GoRoute(path:'/refunds',builder:(c,s)=>const RefundsPage()),
 GoRoute(path:'/review/:productId',builder:(c,s){final shopId=s.uri.queryParameters['shopId']??'';final name=s.uri.queryParameters['name']??'Produit';return ReviewPage(productId:s.pathParameters['productId']!,shopId:shopId,productName:name);}),
 GoRoute(path:'/payment/:orderId',builder:(c,s)=>PaymentPage(orderId:s.pathParameters['orderId']!)),
 GoRoute(path:'/seller/commissions',builder:(c,s)=>const CommissionsPage()),
 GoRoute(path:'/admin',builder:(c,s)=>const AdminDashboardPage()),
 GoRoute(path:'/admin/accounts',builder:(c,s)=>const AdminAccountsPage()),
 GoRoute(path:'/admin/products',builder:(c,s)=>const AdminProductsPage()),
 GoRoute(path:'/admin/modules',builder:(c,s)=>const AdminModulesPage()),
 GoRoute(path:'/admin/delivery-pricing',builder:(c,s)=>const AdminDeliveryPricingPage()),
 GoRoute(path:'/orders',builder:(c,s)=>const OrdersPage()),
 GoRoute(path:'/bookings',builder:(c,s)=>const BookingsPage()),
 GoRoute(path:'/order/:id',builder:(c,s)=>OrderDetailPage(orderId:s.pathParameters['id']!)),
 GoRoute(path:'/addresses',builder:(c,s)=>const AddressesPage()),
 GoRoute(path:'/notifications',builder:(c,s)=>const NotificationsPage()),
 GoRoute(path:'/messages',builder:(c,s)=>const MessagesPage()),
 GoRoute(path:'/conversation/:id',builder:(c,s)=>ConversationPage(conversationId:s.pathParameters['id']!)),
 GoRoute(path:'/seller',builder:(c,s)=>const SellerNavigation()),
 GoRoute(path:'/seller/create-shop',builder:(c,s)=>const SellerCreateShopPage()),
 GoRoute(path:'/seller/orders',builder:(c,s)=>const SellerOrdersPage()),
 GoRoute(path:'/seller/order/:id',builder:(c,s)=>SellerOrderDetailPage(groupId:s.pathParameters['id']!)),
 GoRoute(path:'/seller/stock',builder:(c,s)=>SellerStockPage(shopId:s.uri.queryParameters['shopId']??'')),
 GoRoute(path:'/seller/finance',builder:(c,s)=>const SellerFinancePage()),
 GoRoute(path:'/seller/payouts',builder:(c,s)=>const SellerPayoutsPage()),
 GoRoute(path:'/seller/settings',builder:(c,s)=>const SellerSettingsPage()),
 GoRoute(path:'/courier',builder:(c,s)=>const CourierPage()),
 GoRoute(path:'/delivery/:orderId/:courierId',builder:(c,s)=>DeliveryTrackingPage(orderId:s.pathParameters['orderId']!,courierId:s.pathParameters['courierId']!)),
 GoRoute(path:'/promotions',builder:(c,s)=>const PromotionsPage()),
 GoRoute(path:'/follows',builder:(c,s)=>const FollowsPage()),
 GoRoute(path:'/profile',builder:(c,s)=>const ProfilePage()),
 GoRoute(path:'/auth',builder:(c,s)=>const AuthPage()),
 GoRoute(path:'/restaurants',builder:(c,s)=>const RestaurantsPage()),
 GoRoute(path:'/restaurant/:id',builder:(c,s)=>RestaurantDetailPage(restaurantId:s.pathParameters['id']!)),
 GoRoute(
      path: '/shop/:id',
      builder: (c, s) {
        final shop = s.extra;
        return shop is Shop
            ? ShopDetailPage(shop: shop)
            : ShopDetailPage(shopId: s.pathParameters['id']!);
      },
    ),
 GoRoute(path:'/transport',builder:(c,s)=>const TransportPage()),
 GoRoute(path:'/mechanics',builder:(c,s)=>const MechanicsPage()),
 GoRoute(path:'/services',builder:(c,s)=>const ServicesPage()),
 GoRoute(path:'/group-buy',builder:(c,s)=>const GroupBuyPage()),
 GoRoute(path:'/expiry',builder:(c,s)=>const ExpiryPage()),
 GoRoute(path:'/rides',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.rides)),
 GoRoute(path:'/rentals',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.rentals)),
 GoRoute(path:'/real-estate',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.realEstate)),
 GoRoute(path:'/accommodations',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.accommodations)),
 GoRoute(path:'/events',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.events)),
 GoRoute(path:'/jobs',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.jobs)),
 GoRoute(path:'/professionals',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.professionals)),
 GoRoute(path:'/agriculture',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.agriculture)),
 GoRoute(path:'/freight',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.freight)),
 GoRoute(path:'/health',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.health)),
 GoRoute(path:'/beauty',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.beauty)),
 GoRoute(path:'/home-services',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.homeServices)),
 GoRoute(path:'/digital',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.digital)),
 GoRoute(path:'/training',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.training)),
 GoRoute(path:'/creative',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.creative)),
 GoRoute(path:'/parcels',builder:(c,s)=>const VerticalDiscoveryPage(module: VerticalModule.parcels)),
  ],
);
}