import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_multiservices_burkina/features/modules/domain/marketplace_module.dart';

void main() {
  test('maps an enabled marketplace module', () {
    final module = MarketplaceModule.fromMap({
      'key': 'restaurants',
      'label': 'Restaurants',
      'route': '/restaurants',
      'icon_name': 'restaurant',
      'config': {'version': 1},
    });

    expect(module.key, 'restaurants');
    expect(module.label, 'Restaurants');
    expect(module.route, '/restaurants');
    expect(module.iconName, 'restaurant');
    expect(module.config['version'], 1);
  });
}