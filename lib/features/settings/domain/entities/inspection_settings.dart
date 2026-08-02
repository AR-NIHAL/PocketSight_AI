import 'package:freezed_annotation/freezed_annotation.dart';

import 'fps_mode.dart';

part 'inspection_settings.freezed.dart';
part 'inspection_settings.g.dart';

/// Persisted performance & model controls for the scanner.
@freezed
abstract class InspectionSettings with _$InspectionSettings {
  const factory InspectionSettings({
    @Default(0.5) double confidenceThreshold,
    @Default(FpsMode.balanced) FpsMode fpsMode,
  }) = _InspectionSettings;

  factory InspectionSettings.fromJson(Map<String, dynamic> json) =>
      _$InspectionSettingsFromJson(json);

  const InspectionSettings._();
}
