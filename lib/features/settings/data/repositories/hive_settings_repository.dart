import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../domain/entities/inspection_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Persistent [SettingsRepository] backed by a Hive box.
///
/// Settings are stored as a single JSON-encoded [InspectionSettings] string,
/// reusing the entity's own `toJson`/`fromJson` round-trip.
class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository({String boxName = 'settings', String? path})
      : _boxName = boxName,
        _path = path;

  static const _key = 'inspection_settings';

  final String _boxName;
  final String? _path;
  Future<Box<String>>? _opening;

  Future<Box<String>> _box() =>
      _opening ??= Hive.openBox<String>(_boxName, path: _path);

  @override
  Future<InspectionSettings?> load() async {
    final box = await _box();
    final raw = box.get(_key);
    if (raw == null) return null;
    return InspectionSettings.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(InspectionSettings settings) async {
    final box = await _box();
    await box.put(_key, jsonEncode(settings.toJson()));
  }
}
