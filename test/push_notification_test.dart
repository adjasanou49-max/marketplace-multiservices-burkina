import 'package:flutter_test/flutter_test.dart';

import '../lib/core/navigation/app_navigation.dart';

void main() {
  test('maps order push to order details', () {
    expect(
      notificationRoute({
        'type': 'order_paid',
        'order_id': 'abc123',
      }),
      '/orders/abc123',
    );
  });

  test('maps delivery push to delivery tracking', () {
    expect(
      notificationRoute({
        'type': 'delivery',
        'delivery_order_id': 'abc123',
      }),
      '/delivery/abc123',
    );
  });

  test('maps message push to messages', () {
    expect(
      notificationRoute({'type': 'new_message'}),
      '/messages',
    );
  });

  test('maps promotion push to promotions', () {
    expect(
      notificationRoute({'type': 'promotion'}),
      '/promotions',
    );
  });
}
