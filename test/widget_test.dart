import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/core/app.dart';

const _cameraChannel = MethodChannel('plugins.flutter.io/camera');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // No camera exists in the test environment: make `availableCameras()`
    // resolve immediately (empty list) so the scanner fails fast into its
    // error state instead of waiting forever on a real platform channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_cameraChannel, (call) async {
          if (call.method == 'availableCameras') return <dynamic>[];
          return null;
        });
  });

  testWidgets('app boots and shows the scanner shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PocketSightApp()));
    await tester.pumpAndSettle();

    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    expect(find.text('Camera unavailable'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PocketSightApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();
    expect(find.text('Offline Inventory'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Performance & Model Controls'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Scan'), findsOneWidget);
  });
}
