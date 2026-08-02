import '../entities/inspection_settings.dart';
import '../repositories/settings_repository.dart';

/// Persists [settings].
class SaveSettings {
  const SaveSettings(this._repository);

  final SettingsRepository _repository;

  Future<void> call(InspectionSettings settings) =>
      _repository.save(settings);
}
