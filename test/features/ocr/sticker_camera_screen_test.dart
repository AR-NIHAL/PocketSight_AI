import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/features/ocr/presentation/screens/sticker_camera_screen.dart';

void main() {
  testWidgets('StickerCameraScreen renders viewfinder HUD, guidance text, and controls',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    StickerCameraResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<StickerCameraResult>(
                    MaterialPageRoute(
                      builder: (_) => const StickerCameraScreen(),
                    ),
                  );
                },
                child: const Text('Open Camera'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to open StickerCameraScreen
    await tester.tap(find.text('Open Camera'));
    await tester.pumpAndSettle();

    // Verify top bar elements
    expect(find.text('Scan label'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.flash_off), findsOneWidget);

    // Verify guidance text
    expect(find.text('Keep the sticker clear and in focus'), findsOneWidget);

    // Verify viewfinder painter is present
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify bottom controls
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.text('Enter details manually'), findsOneWidget);

    // Tap "Enter details manually" and verify it pops returning enterManually: true
    await tester.tap(find.text('Enter details manually'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.enterManually, isTrue);
    expect(result!.imagePath, isNull);
  });
}
