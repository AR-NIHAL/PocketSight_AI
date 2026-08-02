import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import '../../domain/entities/fps_mode.dart';
import '../../domain/entities/inspection_settings.dart';

part 'settings_controller.g.dart';

/// Loads, exposes and persists the [InspectionSettings] driving the scanner.
///
/// Mutations update the reactive state immediately and persist the new value
/// so toggles survive restarts.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  Future<InspectionSettings> build() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    return settings ?? const InspectionSettings();
  }

  Future<void> setConfidenceThreshold(double value) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(confidenceThreshold: value);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).save(updated);
  }

  Future<void> setFpsMode(FpsMode mode) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(fpsMode: mode);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).save(updated);
  }
}
