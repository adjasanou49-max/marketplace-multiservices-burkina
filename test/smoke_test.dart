import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marketplace_multiservices_burkina/app.dart';

void main() {
  testWidgets('application boots without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MarketplaceApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Marketplace Burkina'), findsOneWidget);
  });
}
