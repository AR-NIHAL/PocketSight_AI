import 'dart:async';
import 'dart:convert';

import '../../domain/entities/inspection_item.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Ephemeral [InventoryRepository] kept in memory for the app session.
///
/// Satisfies the full contract so the scanner's tap-to-inspect flow is
/// end-to-end and testable before Hive disk wiring lands in Phase 4.
class InMemoryInventoryRepository implements InventoryRepository {
  final List<InspectionItem> _items = [];
  final _controller = StreamController<List<InspectionItem>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(_items));

  @override
  Stream<List<InspectionItem>> watchItems() => _controller.stream;

  @override
  Future<void> saveItem(InspectionItem item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    _emit();
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    _emit();
  }

  @override
  Future<List<InspectionItem>> searchItems({
    String? query,
    String? category,
  }) async {
    final normalizedQuery = query?.toLowerCase();
    return _items.where((item) {
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
  Future<String> exportJson() async =>
      jsonEncode(_items.map((item) => item.toJson()).toList());

  @override
  Future<void> importJson(String json) async {
    final decoded = jsonDecode(json) as List<dynamic>;
    for (final entry in decoded) {
      final item = InspectionItem.fromJson(entry as Map<String, dynamic>);
      await saveItem(item);
    }
  }
}
