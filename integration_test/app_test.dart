import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pocketsite_ai/core/app.dart';

/// On-device sanity check: boots the app and walks the shell tabs.
///
/// Deliberately device-state independent — it asserts on the navigation
/// shell and on screen elements that are present regardless of whether the
/// camera is available or the inventory already contains items.
///
/// Run with: `flutter test integration_test -d <device-id>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and navigates between the three tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PocketSightApp()));
    // Fixed pumps instead of pumpAndSettle: a live camera preview keeps
    // scheduling frames, which would make pumpAndSettle spin until timeout.
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Inventory'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Search inventory'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Confidence threshold'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Scan'), findsOneWidget);
  });
}
