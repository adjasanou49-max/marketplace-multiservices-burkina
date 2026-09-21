import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

String notificationRoute(Map<String, dynamic> data) {
  final explicit = data['route']?.toString().trim();
  if (explicit != null && explicit.isNotEmpty && explicit.startsWith('/')) {
    return explicit;
  }

  final orderId = data['order_id']?.toString().trim();
  final deliveryOrderId = data['delivery_order_id']?.toString().trim();
  final type = (data['type'] ?? '').toString().toLowerCase();

  if (deliveryOrderId != null && deliveryOrderId.isNotEmpty) {
    return '/delivery/' + deliveryOrderId;
  }

  if (orderId != null && orderId.isNotEmpty) {
    return '/orders/' + orderId;
  }

  if (type.contains('message') || type.contains('chat')) return '/messages';
  if (type.contains('promotion') || type.contains('coupon')) {
    return '/promotions';
  }
  if (type.contains('transport')) return '/transport';
  if (type.contains('mechanic') || type.contains('service')) {
    return '/services';
  }

  return '/notifications';
}

void openNotificationRoute(Map<String, dynamic> data) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;
  final route = notificationRoute(data);
  GoRouter.of(context).go(route);
}
