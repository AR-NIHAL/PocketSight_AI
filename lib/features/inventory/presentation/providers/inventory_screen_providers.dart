import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import '../../domain/entities/inspection_item.dart';

part 'inventory_screen_providers.g.dart';

/// Reactive snapshot of the whole inventory, updated on every change.
@riverpod
Stream<List<InspectionItem>> inventoryItems(Ref ref) =>
    ref.watch(inventoryRepositoryProvider).watchItems();
