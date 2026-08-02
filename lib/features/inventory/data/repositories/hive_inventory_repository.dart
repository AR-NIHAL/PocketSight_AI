import 'dart:async';
import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../domain/entities/inspection_item.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Persistent [InventoryRepository] backed by a Hive box.
///
/// Each [InspectionItem] is stored as a JSON-encoded string keyed by its `id`,
/// so the freezed entity's own `toJson`/`fromJson` round-trip exactly without
/// needing a dedicated Hive type adapter.
///
/// A [path] can be supplied (used by tests); when omitted the box is opened
/// at Hive's configured home path, so `Hive.initFlutter()` must have run first.
class HiveInventoryRepository implements InventoryRepository {
  HiveInventoryRepository({String boxName = 'inventory', String? path})
      : _boxName = boxName,
        _path = path;

  final String _boxName;
  final String? _path;
  final _controller = StreamController<List<InspectionItem>>.broadcast();
  Future<Box<String>>? _opening;

  Future<Box<String>> _box() =>
      _opening ??= Hive.openBox<String>(_boxName, path: _path);

  static InspectionItem _fromJson(String json) =>
      InspectionItem.fromJson(jsonDecode(json) as Map<String, dynamic>);

  /// Reads the current box state and broadcasts it to listeners.
  Future<void> _emit() async {
    final box = await _box();
    final items = box.values.map(_fromJson).toList();
    _controller.add(List.unmodifiable(items));
  }

  @override
  Stream<List<InspectionItem>> watchItems() {
    // Emit the current snapshot so a new listener never sits on loading.
    _emit();
    return _controller.stream;
  }

  @override
  Future<void> saveItem(InspectionItem item) async {
    final box = await _box();
    await box.put(item.id, jsonEncode(item.toJson()));
    await _emit();
  }

  @override
  Future<void> deleteItem(String id) async {
    final box = await _box();
    await box.delete(id);
    await _emit();
  }

  @override
  Future<List<InspectionItem>> searchItems({
    String? query,
    String? category,
  }) async {
    final box = await _box();
    final normalizedQuery = query?.toLowerCase();
    return box.values.map(_fromJson).where((item) {
      final matchesQuery = normalizedQuery == null ||
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.markdownNotes.toLowerCase().contains(normalizedQuery);
      final matchesCategory = category == null ||
          category.isEmpty ||
          item.category.toLowerCase() == category.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Future<String> exportJson() async {
    final box = await _box();
    final items = box.values.map(_fromJson).toList();
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  @override
  Future<void> importJson(String json) async {
    final box = await _box();
    final decoded = jsonDecode(json) as List<dynamic>;
    for (final entry in decoded) {
      final item = InspectionItem.fromJson(entry as Map<String, dynamic>);
      await box.put(item.id, jsonEncode(item.toJson()));
    }
    await _emit();
  }
}
