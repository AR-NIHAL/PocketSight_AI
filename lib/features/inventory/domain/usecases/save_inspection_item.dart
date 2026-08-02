import '../entities/inspection_item.dart';
import '../repositories/inventory_repository.dart';

/// Inserts or updates an [InspectionItem] (upsert by `id`).
class SaveInspectionItem {
  const SaveInspectionItem(this._repository);

  final InventoryRepository _repository;

  Future<void> call(InspectionItem item) => _repository.saveItem(item);
}
