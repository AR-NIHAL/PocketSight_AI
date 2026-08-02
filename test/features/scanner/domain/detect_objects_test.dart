import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pocketsite_ai/features/scanner/domain/entities/detected_object.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/detection_image.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/detection_image_format.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/normalized_rect.dart';
import 'package:pocketsite_ai/features/scanner/domain/repositories/object_detection_repository.dart';
import 'package:pocketsite_ai/features/scanner/domain/usecases/detect_objects.dart';

class MockObjectDetectionRepository extends Mock
    implements ObjectDetectionRepository {}

void main() {
  group('DetectObjects', () {
    late MockObjectDetectionRepository repository;
    late DetectObjects useCase;

    setUp(() {
      repository = MockObjectDetectionRepository();
      useCase = DetectObjects(repository);
    });

    setUpAll(() {
      registerFallbackValue(DetectionImage(
        bytes: Uint8List(0),
        width: 0,
        height: 0,
      ));
    });

    test('delegates to the repository and returns detections', () async {
      final image = DetectionImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
        format: DetectionImageFormat.nv21,
      );
      const box = NormalizedRect(left: 0, top: 0, right: 0.5, bottom: 0.5);
      const detections = [
        DetectedObject(id: 'd-1', label: 'plant', confidence: 0.9, boundingBox: box),
      ];

      when(() => repository.detect(any())).thenAnswer((_) async => detections);

      final result = await useCase(image);

      expect(result, detections);
      verify(() => repository.detect(image)).called(1);
    });
  });
}
