import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/core/app.dart';

void main() {
  testWidgets('app boots and shows the scanner shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PocketSightApp()));

    expect(find.text('PocketSight'), findsOneWidget);
    expect(find.text('Live Scanner'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PocketSightApp()));

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();
    expect(find.text('Offline Inventory'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Performance & Model Controls'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Live Scanner'), findsOneWidget);
  });
}
