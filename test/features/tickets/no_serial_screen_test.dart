import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/features/tickets/presentation/screens/no_serial_screen.dart';

void main() {
  testWidgets('NoSerialNumberScreen displays Screen 05 info banner, shop ID card, and returns result',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    NoSerialResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<NoSerialResult>(
                    MaterialPageRoute(
                      builder: (_) => const NoSerialNumberScreen(sequenceNumber: 42),
                    ),
                  );
                },
                child: const Text('Open No Serial'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open No Serial'));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('No serial number'), findsOneWidget);

    // Verify Blue Info Banner
    expect(find.text('You can still create a repair ticket'), findsOneWidget);
    expect(find.text('Use a shop device ID to track this device in your workshop.'), findsOneWidget);

    // Verify Shop Device ID Card (DEV-0042)
    expect(find.text('Shop Device ID'), findsOneWidget);
    expect(find.text('DEV-0042'), findsOneWidget);
    expect(find.text('Write this ID on a tag attached to the device.'), findsOneWidget);

    // Verify Reason dropdown and Continue button
    expect(find.text('Reason'), findsOneWidget);
    expect(find.text('Continue with Device ID'), findsOneWidget);

    // Tap "Continue with Device ID"
    await tester.tap(find.text('Continue with Device ID'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.deviceId, 'DEV-0042');
    expect(result!.reason, 'Sticker missing');
  });
}
