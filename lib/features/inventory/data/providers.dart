import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/hive_inventory_repository.dart';
import '../data/services/inventory_backup_service.dart';
import '../domain/repositories/inventory_repository.dart';

part 'providers.g.dart';

/// Hive-backed persistent inventory store for the app lifetime.
@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(Ref ref) =>
    HiveInventoryRepository();

/// Platform I/O for JSON backup export/import against the inventory.
@Riverpod(keepAlive: true)
InventoryBackupService inventoryBackupService(Ref ref) =>
    InventoryBackupService(ref.watch(inventoryRepositoryProvider));
