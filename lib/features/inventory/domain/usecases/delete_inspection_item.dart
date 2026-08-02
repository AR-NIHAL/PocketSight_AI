import '../repositories/inventory_repository.dart';

/// Deletes an inventory item by [id].
class DeleteInspectionItem {
  const DeleteInspectionItem(this._repository);

  final InventoryRepository _repository;

  Future<void> call(String id) => _repository.deleteItem(id);
}
