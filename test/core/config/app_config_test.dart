import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_multiservices_burkina/core/config/app_config.dart';

void main() {
  test('production environment is detected', () {
    const config = AppConfig(environment: 'production');
    expect(config.isProduction, isTrue);
    expect(config.isStaging, isFalse);
  });
}
