import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_multiservices_burkina/features/verticals/data/vertical_repository.dart';

void main() {
  test('every vertical module has a configuration', () {
    expect(
      VerticalRepository.configs.length,
      VerticalModule.values.length,
    );

    for (final module in VerticalModule.values) {
      final config = VerticalRepository.configs[module];
      expect(config, isNotNull);
      expect(config!.table, isNotEmpty);
      expect(config.title, isNotEmpty);
      expect(config.select, isNotEmpty);
    }
  });

  test('customer-owned verticals remain scoped to the current customer', () {
    expect(
      VerticalRepository.configs[VerticalModule.rides]!.ownOnly,
      isTrue,
    );
    expect(
      VerticalRepository.configs[VerticalModule.freight]!.ownOnly,
      isTrue,
    );
    expect(
      VerticalRepository.configs[VerticalModule.parcels]!.ownOnly,
      isTrue,
    );
  });
}
