import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/settings/data/providers.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/fps_mode.dart';
import 'package:pocketsite_ai/features/settings/domain/entities/inspection_settings.dart';
import 'package:pocketsite_ai/features/settings/domain/repositories/settings_repository.dart';
import 'package:pocketsite_ai/features/settings/presentation/notifiers/settings_controller.dart';

class _FakeSettingsRepository implements SettingsRepository {
  InspectionSettings? stored;

  @override
  Future<InspectionSettings?> load() async => stored;

  @override
  Future<void> save(InspectionSettings settings) async {
    stored = settings;
  }
}

void main() {
  ProviderContainer containerWith(_FakeSettingsRepository repository) {
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads persisted settings when present', () async {
    final repository = _FakeSettingsRepository()
      ..stored = const InspectionSettings(
        confidenceThreshold: 0.7,
        fpsMode: FpsMode.high,
      );
    final container = containerWith(repository);

    final controller = container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);

    expect(controller.state.value?.confidenceThreshold, 0.7);
    expect(controller.state.value?.fpsMode, FpsMode.high);
  });

  test('falls back to defaults when nothing is stored', () async {
    final container = containerWith(_FakeSettingsRepository());

    await container.read(settingsControllerProvider.future);

    expect(
      container.read(settingsControllerProvider).value,
      const InspectionSettings(),
    );
  });

  test('setConfidenceThreshold updates state and persists', () async {
    final repository = _FakeSettingsRepository();
    final container = containerWith(repository);
    final controller = container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);

    await controller.setConfidenceThreshold(0.9);

    expect(container.read(settingsControllerProvider).value?.confidenceThreshold,
        0.9);
    expect(repository.stored?.confidenceThreshold, 0.9);
  });

  test('setFpsMode updates state and persists', () async {
    final repository = _FakeSettingsRepository();
    final container = containerWith(repository);
    final controller = container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);

    await controller.setFpsMode(FpsMode.low);

    expect(container.read(settingsControllerProvider).value?.fpsMode,
        FpsMode.low);
    expect(repository.stored?.fpsMode, FpsMode.low);
  });
}
