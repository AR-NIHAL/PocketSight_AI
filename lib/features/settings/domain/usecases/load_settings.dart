import '../entities/inspection_settings.dart';
import '../repositories/settings_repository.dart';

/// Loads saved settings, falling back to defaults when none are stored.
class LoadSettings {
  const LoadSettings(this._repository);

  final SettingsRepository _repository;

  Future<InspectionSettings> call() async =>
      await _repository.load() ?? const InspectionSettings();
}
