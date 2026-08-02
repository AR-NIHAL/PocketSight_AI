import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/hive_settings_repository.dart';
import '../domain/repositories/settings_repository.dart';

part 'providers.g.dart';

/// Hive-backed persistent scanner settings store.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => HiveSettingsRepository();
