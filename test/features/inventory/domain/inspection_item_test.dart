import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_item.dart';
import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_schedule.dart';

void main() {
  group('InspectionItem', () {
    test('applies sensible defaults', () {
      final item = InspectionItem(
        id: 'id-1',
        title: 'Monstera',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(item.category, 'Uncategorized');
      expect(item.markdownNotes, '');
      expect(item.thumbnailPath, isNull);
      expect(item.detectionLabel, isNull);
      expect(item.detectionConfidence, isNull);
      expect(item.schedule, isNull);
    });

    test('supports copyWith', () {
      final item = InspectionItem(
        id: 'id-1',
        title: 'Monstera',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(item.copyWith(title: 'Snake Plant').title, 'Snake Plant');
      expect(item.copyWith(title: 'Snake Plant'), isNot(item));
    });

    test('round-trips through JSON with all fields', () {
      final item = InspectionItem(
        id: 'id-1',
        title: 'Monstera',
        category: 'Plants',
        markdownNotes: '# Care\n- Bright light',
        thumbnailPath: '/tmp/thumb.jpg',
        detectionLabel: 'plant',
        detectionConfidence: 0.92,
        schedule: InspectionSchedule(
          nextDueDate: DateTime.utc(2026, 9, 1),
          note: 'Water',
        ),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final restored = InspectionItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );

      expect(restored, item);
    });

    test('round-trips through JSON with defaults', () {
      final item = InspectionItem(
        id: 'id-2',
        title: 'Snake Plant',
        createdAt: DateTime.utc(2026, 3, 1),
        updatedAt: DateTime.utc(2026, 3, 2),
      );

      final restored = InspectionItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>,
      );

      expect(restored, item);
      expect(restored.category, 'Uncategorized');
    });
  });
}
