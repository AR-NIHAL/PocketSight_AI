import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/features/ocr/domain/entities/ocr_candidate.dart';
import 'package:pocketsite_ai/features/ocr/presentation/screens/review_label_screen.dart';
import 'package:pocketsite_ai/features/ocr/presentation/widgets/ocr_review_sheet.dart';

void main() {
  testWidgets('ReviewLabelScreen displays Screen 04 UI and confirms verified details',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final candidates = [
      const OcrCandidate(
        type: CandidateType.serial,
        value: '7B3K9X2',
        confidence: 0.95,
        sourceLine: 'Service Tag: 7B3K9X2',
      ),
      const OcrCandidate(
        type: CandidateType.model,
        value: 'DemoBook 14',
        confidence: 0.90,
        sourceLine: 'Model: DemoBook 14',
      ),
    ];

    OcrReviewResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<OcrReviewResult>(
                    MaterialPageRoute(
                      builder: (_) => ReviewLabelScreen(
                        imagePath: 'test_sticker.jpg',
                        candidates: candidates,
                      ),
                    ),
                  );
                },
                child: const Text('Open Review'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Review'));
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Review label'), findsOneWidget);

    // Verify Amber Warning Banner
    expect(find.text('Check the text before saving'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    // Verify Fields and Candidate Prepopulation
    expect(find.text('Serial number'), findsOneWidget);
    expect(find.text('7B3K9X2'), findsWidgets);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('DemoBook 14'), findsWidgets);

    // Verify Helper note
    expect(find.text('Correct any characters that were read incorrectly.'), findsOneWidget);

    // Verify Retake photo button
    expect(find.text('Retake photo'), findsOneWidget);

    // Verify Confirm details button
    expect(find.text('Confirm details'), findsOneWidget);

    // Tap "Confirm details" and check result
    await tester.tap(find.text('Confirm details'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isVerified, isTrue);
    expect(result!.serialNumber, '7B3K9X2');
    expect(result!.model, 'DemoBook 14');
    expect(result!.retakePhoto, isFalse);
  });
}
