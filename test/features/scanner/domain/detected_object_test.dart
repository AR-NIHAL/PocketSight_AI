import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/scanner/domain/entities/detected_object.dart';
import 'package:pocketsite_ai/features/scanner/domain/entities/normalized_rect.dart';

void main() {
  group('DetectedObject', () {
    const box = NormalizedRect(left: 0.1, top: 0.1, right: 0.4, bottom: 0.5);

    test('exposes detection fields', () {
      const obj = DetectedObject(
        id: 'd-1',
        label: 'plant',
        confidence: 0.87,
        boundingBox: box,
        trackingId: 3,
      );
      expect(obj.id, 'd-1');
      expect(obj.label, 'plant');
      expect(obj.confidence, 0.87);
      expect(obj.boundingBox, box);
      expect(obj.trackingId, 3);
    });

    test('trackingId is optional', () {
      const obj = DetectedObject(
        id: 'd-2',
        label: 'plant',
        confidence: 0.5,
        boundingBox: box,
      );
      expect(obj.trackingId, isNull);
    });

    test('supports value equality and copyWith', () {
      const obj = DetectedObject(
        id: 'd-1',
        label: 'plant',
        confidence: 0.87,
        boundingBox: box,
      );
      expect(obj.copyWith(confidence: 0.99).confidence, 0.99);
      expect(obj.copyWith(confidence: 0.99), isNot(obj));
    });
  });
}
