import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_page.dart';
import '../features/products/domain/product.dart';
import '../features/products/presentation/product_detail_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/checkout/presentation/checkout_page.dart';
import '../features/payments/presentation/payment_page.dart';
import '../features/refunds/presentation/refunds_page.dart';
import '../features/commissions/presentation/commissions_page.dart';
import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/admin/presentation/admin_accounts_page.dart';
import '../features/admin/presentation/admin_products_page.dart';
import '../features/admin/presentation/admin_modules_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/addresses/presentation/addresses_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/messaging/presentation/messages_page.dart';
import '../features/seller/presentation/seller_dashboard_page.dart';
import '../features/seller/presentation/seller_orders_page.dart';
import '../features/seller/presentation/seller_order_detail_page.dart';
import '../features/seller/presentation/seller_stock_page.dart';
import '../features/seller/presentation/seller_finance_page.dart';
import '../features/seller/presentation/seller_payouts_page.dart';
import '../features/promotions/presentation/promotions_page.dart';
import '../features/follows/presentation/follows_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/restaurants/presentation/restaurants_page.dart';
import '../features/shops/presentation/shop_detail_page.dart';
import '../features/shops/domain/shop.dart';
import '../features/transport/presentation/transport_page.dart';
import '../features/mechanics/presentation/mechanics_page.dart';
import '../features/services/presentation/services_page.dart';
import '../features/group_buy/presentation/group_buy_page.dart';
import '../features/expiry/presentation/expiry_page.dart';

final appRouter=GoRouter(initialLocation:'/',routes:[
 GoRoute(path:'/',builder:(c,s)=>const HomePage()),
 GoRoute(path:'/search',builder:(c,s)=>const SearchPage()),
 GoRoute(path:'/product/:id',builder:(c,s){final product=s.extra;return product is Product ? ProductDetailPage(product:product) : const Scaffold(body:Center(child:Text('Produit introuvable')));}),
 GoRoute(path:'/cart',builder:(c,s)=>const CartPage()),
 GoRoute(path:'/checkout',builder:(c,s)=>const CheckoutPage()),
 GoRoute(path:'/refunds',builder:(c,s)=>const RefundsPage()),
 GoRoute(path:'/payment/:orderId',builder:(c,s)=>PaymentPage(orderId:s.pathParameters['orderId']!)),
 GoRoute(path:'/seller/commissions',builder:(c,s)=>const CommissionsPage()),
 GoRoute(path:'/admin',builder:(c,s)=>const AdminDashboardPage()),
 GoRoute(path:'/admin/accounts',builder:(c,s)=>const AdminAccountsPage()),
 GoRoute(path:'/admin/products',builder:(c,s)=>const AdminProductsPage()),
 GoRoute(path:'/admin/modules',builder:(c,s)=>const AdminModulesPage()),
 GoRoute(path:'/orders',builder:(c,s)=>const OrdersPage()),
 GoRoute(path:'/addresses',builder:(c,s)=>const AddressesPage()),
 GoRoute(path:'/notifications',builder:(c,s)=>const NotificationsPage()),
 GoRoute(path:'/messages',builder:(c,s)=>const MessagesPage()),
 GoRoute(path:'/seller',builder:(c,s)=>const SellerDashboardPage()),
 GoRoute(path:'/seller/orders',builder:(c,s)=>const SellerOrdersPage()),
 GoRoute(path:'/seller/order/:id',builder:(c,s)=>SellerOrderDetailPage(groupId:s.pathParameters['id']!)),
 GoRoute(path:'/seller/stock',builder:(c,s)=>SellerStockPage(shopId:s.uri.queryParameters['shopId']??'')),
 GoRoute(path:'/seller/finance',builder:(c,s)=>const SellerFinancePage()),
 GoRoute(path:'/seller/payouts',builder:(c,s)=>const SellerPayoutsPage()),
 GoRoute(path:'/promotions',builder:(c,s)=>const PromotionsPage()),
 GoRoute(path:'/follows',builder:(c,s)=>const FollowsPage()),
 GoRoute(path:'/profile',builder:(c,s)=>const ProfilePage()),
 GoRoute(path:'/auth',builder:(c,s)=>const AuthPage()),
 GoRoute(path:'/restaurants',builder:(c,s)=>const RestaurantsPage()),
 GoRoute(path:'/shop/:id',builder:(c,s){final shop=s.extra;return shop is Shop ? ShopDetailPage(shop:shop) : const Scaffold(body:Center(child:Text('Boutique introuvable')));}),
 GoRoute(path:'/transport',builder:(c,s)=>const TransportPage()),
 GoRoute(path:'/mechanics',builder:(c,s)=>const MechanicsPage()),
 GoRoute(path:'/services',builder:(c,s)=>const ServicesPage()),
 GoRoute(path:'/group-buy',builder:(c,s)=>const GroupBuyPage()),
 GoRoute(path:'/expiry',builder:(c,s)=>const ExpiryPage()),
]);