import '../repositories/inventory_repository.dart';

/// Restores the inventory from a previously exported [json] string.
class ImportInventory {
  const ImportInventory(this._repository);

  final InventoryRepository _repository;

  Future<void> call(String json) => _repository.importJson(json);
}
