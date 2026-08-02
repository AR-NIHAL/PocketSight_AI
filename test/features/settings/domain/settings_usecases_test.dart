import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pocketsite_ai/features/settings/domain/entities/fps_mode.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/inspection_settings.dart';
import 'package:pocketsite_ai/features/settings/domain/repositories/settings_repository.dart';
import 'package:pocketsite_ai/features/settings/domain/usecases/load_settings.dart';
import 'package:pocketsite_ai/features/settings/domain/usecases/save_settings.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  test('LoadSettings returns saved settings when present', () async {
    const saved = InspectionSettings(confidenceThreshold: 0.7);
    when(() => repository.load()).thenAnswer((_) async => saved);

    final useCase = LoadSettings(repository);
    expect(await useCase(), saved);
  });

  test('LoadSettings falls back to defaults when nothing is stored', () async {
    when(() => repository.load()).thenAnswer((_) async => null);

    final useCase = LoadSettings(repository);
    expect(await useCase(), const InspectionSettings());
  });

  test('SaveSettings forwards settings to the repository', () async {
    const settings = InspectionSettings(
      confidenceThreshold: 0.9,
      fpsMode: FpsMode.high,
    );
    when(() => repository.save(settings)).thenAnswer((_) async {});

    final useCase = SaveSettings(repository);
    await useCase(settings);

    verify(() => repository.save(settings)).called(1);
  });
}
