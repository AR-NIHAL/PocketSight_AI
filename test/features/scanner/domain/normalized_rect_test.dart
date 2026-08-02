import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/scanner/domain/entities/normalized_rect.dart';

void main() {
  group('NormalizedRect', () {
    test('is valid for an in-range positive-area rect', () {
      const rect = NormalizedRect(left: 0.1, top: 0.1, right: 0.5, bottom: 0.6);
      expect(rect.isValid, isTrue);
    });

    test('is invalid when coordinates exceed the unit range', () {
      const rect = NormalizedRect(left: 0, top: 0, right: 1.2, bottom: 1);
      expect(rect.isValid, isFalse);
    });

    test('is invalid when coordinates are negative', () {
      const rect = NormalizedRect(left: -0.1, top: 0, right: 0.5, bottom: 0.5);
      expect(rect.isValid, isFalse);
    });

    test('is invalid for a zero-area box', () {
      const rect = NormalizedRect(left: 0.5, top: 0.5, right: 0.5, bottom: 0.8);
      expect(rect.isValid, isFalse);
    });

    test('supports value equality and copyWith', () {
      const rect = NormalizedRect(left: 0.1, top: 0.2, right: 0.3, bottom: 0.4);
      expect(rect.copyWith(right: 0.9), isNot(rect));
      expect(const NormalizedRect(left: 0.1, top: 0.2, right: 0.3, bottom: 0.4), rect);
    });
  });
}
