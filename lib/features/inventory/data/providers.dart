import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/in_memory_inventory_repository.dart';
import '../domain/repositories/inventory_repository.dart';

part 'providers.g.dart';

/// In-memory inventory store for the app session (Hive-backed in Phase 4).
@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(Ref ref) =>
    InMemoryInventoryRepository();
