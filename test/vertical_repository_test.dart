import 'package:flutter_test/flutter_test.dart';

import 'package:marketplace_multiservices_burkina/features/verticals/data/vertical_repository.dart';

void main() {
  test('all vertical modules have complete configuration', () {
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

  test('private verticals use an explicit ownership column', () {
    final privateModules = VerticalRepository.configs.entries
        .where((entry) => entry.value.ownOnly)
        .toList();

    expect(privateModules, isNotEmpty);

    for (final entry in privateModules) {
      expect(entry.value.ownUserColumn, isNotEmpty);
    }

    expect(
      VerticalRepository.configs[VerticalModule.parcels]!.ownUserColumn,
      'sender_id',
    );
  });
}
