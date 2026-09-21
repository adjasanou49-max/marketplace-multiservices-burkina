import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/checkout/presentation/checkout_page.dart';
import '../features/refunds/presentation/refunds_page.dart';
import '../features/commissions/presentation/commissions_page.dart';
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

final appRouter=GoRouter(initialLocation:'/',routes:[
 GoRoute(path:'/',builder:(c,s)=>const HomePage()),
 GoRoute(path:'/search',builder:(c,s)=>const SearchPage()),
 GoRoute(path:'/cart',builder:(c,s)=>const CartPage()),
 GoRoute(path:'/checkout',builder:(c,s)=>const CheckoutPage()),
 GoRoute(path:'/refunds',builder:(c,s)=>const RefundsPage()),
 GoRoute(path:'/seller/commissions',builder:(c,s)=>const CommissionsPage()),
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
]);