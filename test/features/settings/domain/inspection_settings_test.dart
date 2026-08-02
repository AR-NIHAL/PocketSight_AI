import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/settings/domain/entities/fps_mode.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/inspection_settings.dart';

void main() {
  group('InspectionSettings', () {
    test('applies defaults', () {
      const settings = InspectionSettings();
      expect(settings.confidenceThreshold, 0.5);
      expect(settings.fpsMode, FpsMode.balanced);
    });

    test('supports copyWith', () {
      const settings = InspectionSettings();
      expect(settings.copyWith(confidenceThreshold: 0.8).confidenceThreshold, 0.8);
      expect(settings.copyWith(fpsMode: FpsMode.high).fpsMode, FpsMode.high);
    });

    test('round-trips through JSON', () {
      const settings = InspectionSettings(
        confidenceThreshold: 0.65,
        fpsMode: FpsMode.high,
      );
      final restored = InspectionSettings.fromJson(
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
      );
      expect(restored, settings);
    });

    test('FpsMode exposes target frames per second', () {
      expect(FpsMode.low.targetFps, 10);
      expect(FpsMode.balanced.targetFps, 12);
      expect(FpsMode.high.targetFps, 15);
    });
  });
}
