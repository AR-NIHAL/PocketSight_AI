import '../entities/inspection_settings.dart';

/// Contract for persisting scanner settings locally.
abstract interface class SettingsRepository {
  /// Loads the saved settings, or `null` if none were saved yet.
  Future<InspectionSettings?> load();

  /// Persists [settings].
  Future<void> save(InspectionSettings settings);
}
