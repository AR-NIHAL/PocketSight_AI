import '../entities/inspection_item.dart';

/// Contract for the offline local inventory database.
abstract interface class InventoryRepository {
  /// Emits the current inventory snapshot reactively, whenever items change.
  Stream<List<InspectionItem>> watchItems();

  /// Inserts or updates [item] (upsert by `id`).
  Future<void> saveItem(InspectionItem item);

  /// Deletes the item with [id] (no-op if it does not exist).
  Future<void> deleteItem(String id);

  /// Returns items whose title/notes match [query] and whose category
  /// matches [category] (case-insensitive; null/empty means "no filter").
  Future<List<InspectionItem>> searchItems({
    String? query,
    String? category,
  });

  /// Serializes the whole inventory to a JSON string for local backup.
  Future<String> exportJson();

  /// Replaces/merges the inventory from a previously exported [json] string.
  Future<void> importJson(String json);
}
