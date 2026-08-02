import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart' as commons;
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as ml;
import 'package:mocktail/mocktail.dart';

import 'package:pocketsite_ai/features/scanner/data/repositories/mlkit_object_detection_repository.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/detection_image.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/detection_image_format.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/normalized_rect.dart';

class MockObjectDetector extends Mock implements ml.ObjectDetector {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      commons.InputImage.fromBytes(
        bytes: Uint8List(0),
        metadata: commons.InputImageMetadata(
          size: const Size(1, 1),
          rotation: commons.InputImageRotation.rotation0deg,
          format: commons.InputImageFormat.nv21,
          bytesPerRow: 0,
        ),
      ),
    );
  });

  group('MlKitObjectDetectionRepository', () {
    late MockObjectDetector detector;
    late MlKitObjectDetectionRepository repository;

    setUp(() {
      detector = MockObjectDetector();
      repository = MlKitObjectDetectionRepository(
        confidenceThreshold: 0.5,
        detector: detector,
      );
      when(() => detector.close()).thenAnswer((_) async {});
    });

    DetectionImage image({
      int rotationDegrees = 0,
      DetectionImageFormat format = DetectionImageFormat.nv21,
    }) {
      return DetectionImage(
        bytes: Uint8List.fromList(List.filled(24, 0)),
        width: 100,
        height: 200,
        format: format,
        rotationDegrees: rotationDegrees,
      );
    }

    test('maps detected objects to the domain model', () async {
      when(() => detector.processImage(any())).thenAnswer(
        (_) async => [
          ml.DetectedObject(
            boundingBox: const Rect.fromLTWH(0, 0, 50, 100),
            trackingId: 3,
            labels: [
              ml.Label(index: 0, text: 'plant', confidence: 0.9),
            ],
          ),
        ],
      );

      final results = await repository.detect(image());

      expect(results, hasLength(1));
      final result = results.single;
      expect(result.label, 'plant');
      expect(result.confidence, 0.9);
      expect(result.trackingId, 3);
      expect(result.boundingBox, const NormalizedRect(
        left: 0,
        top: 0,
        right: 0.5,
        bottom: 0.5,
      ));
    });

    test('filters out objects below the confidence threshold', () async {
      when(() => detector.processImage(any())).thenAnswer(
        (_) async => [
          ml.DetectedObject(
            boundingBox: const Rect.fromLTWH(0, 0, 50, 100),
            trackingId: 1,
            labels: [
              ml.Label(index: 0, text: 'plant', confidence: 0.4),
            ],
          ),
        ],
      );

      final results = await repository.detect(image());

      expect(results, isEmpty);
    });

    test('falls back to a generic label when no labels exist', () async {
      final zeroThreshold = MlKitObjectDetectionRepository(
        confidenceThreshold: 0,
        detector: detector,
      );
      when(() => detector.processImage(any())).thenAnswer(
        (_) async => [
          ml.DetectedObject(
            boundingBox: const Rect.fromLTWH(0, 0, 25, 50),
            trackingId: null,
            labels: const [],
          ),
        ],
      );

      final results = await zeroThreshold.detect(image());

      expect(results, hasLength(1));
      expect(results.single.label, 'object');
      expect(results.single.confidence, 0);
    });

    test('picks the highest-confidence label for an object', () async {
      when(() => detector.processImage(any())).thenAnswer(
        (_) async => [
          ml.DetectedObject(
            boundingBox: const Rect.fromLTWH(0, 0, 50, 100),
            trackingId: 2,
            labels: [
              ml.Label(index: 0, text: 'leaf', confidence: 0.6),
              ml.Label(index: 1, text: 'plant', confidence: 0.8),
            ],
          ),
        ],
      );

      final results = await repository.detect(image());

      expect(results.single.label, 'plant');
    });

    test('normalizes boxes against rotated dimensions for 90 degrees',
        () async {
      when(() => detector.processImage(any())).thenAnswer(
        (_) async => [
          ml.DetectedObject(
            boundingBox: const Rect.fromLTWH(0, 0, 50, 100),
            trackingId: null,
            labels: [
              ml.Label(index: 0, text: 'plant', confidence: 0.9),
            ],
          ),
        ],
      );

      final results = await repository.detect(image(rotationDegrees: 90));

      expect(results.single.boundingBox, const NormalizedRect(
        left: 0,
        top: 0,
        right: 0.25,
        bottom: 1,
      ));
    });

    test('throws for unsupported image formats', () async {
      final input = image(format: DetectionImageFormat.jpeg);

      expect(
        () => repository.detect(input),
        throwsUnsupportedError,
      );
    });

    test('closes the underlying detector on dispose', () async {
      await repository.dispose();

      verify(() => detector.close()).called(1);
    });
  });
}
