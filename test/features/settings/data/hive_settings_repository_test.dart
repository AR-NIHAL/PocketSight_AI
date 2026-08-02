import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:pocketsite_ai/features/settings/data/repositories/hive_settings_repository.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/fps_mode.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/inspection_settings.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_settings_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('HiveSettingsRepository', () {
    test('returns null when nothing has been saved', () async {
      final repository = HiveSettingsRepository();
      expect(await repository.load(), isNull);
    });

    test('round-trips settings through save and load', () async {
      const settings = InspectionSettings(
        confidenceThreshold: 0.8,
        fpsMode: FpsMode.high,
      );
      final repository = HiveSettingsRepository();

      await repository.save(settings);

      expect(await repository.load(), settings);
    });

    test('persists across repository instances', () async {
      final writer = HiveSettingsRepository();
      await writer.save(
        const InspectionSettings(confidenceThreshold: 0.3),
      );

      final reader = HiveSettingsRepository();
      final loaded = await reader.load();

      expect(loaded, isNotNull);
      expect(loaded!.confidenceThreshold, 0.3);
      expect(loaded.fpsMode, FpsMode.balanced);
    });
  });
}
