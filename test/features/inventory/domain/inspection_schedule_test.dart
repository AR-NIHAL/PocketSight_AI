import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_schedule.dart';

void main() {
  group('InspectionSchedule', () {
    test('exposes due date and optional note', () {
      final schedule = InspectionSchedule(
        nextDueDate: DateTime.utc(2026, 9, 1),
        note: 'Water thoroughly',
      );
      expect(schedule.nextDueDate, DateTime.utc(2026, 9, 1));
      expect(schedule.note, 'Water thoroughly');
    });

    test('note is optional', () {
      final schedule = InspectionSchedule(nextDueDate: DateTime.utc(2026, 9, 1));
      expect(schedule.note, isNull);
    });

    test('round-trips through JSON', () {
      final schedule = InspectionSchedule(
        nextDueDate: DateTime.utc(2026, 9, 1, 10, 30),
        note: 'Inspect leaves',
      );
      final restored = InspectionSchedule.fromJson(
        jsonDecode(jsonEncode(schedule.toJson())) as Map<String, dynamic>,
      );
      expect(restored, schedule);
    });

    test('supports copyWith', () {
      final schedule = InspectionSchedule(nextDueDate: DateTime.utc(2026, 9, 1));
      expect(schedule.copyWith(note: 'x').note, 'x');
    });
  });
}
