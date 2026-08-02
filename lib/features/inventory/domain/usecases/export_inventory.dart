import '../repositories/inventory_repository.dart';

/// Serializes the inventory to a JSON string for local backup.
class ExportInventory {
  const ExportInventory(this._repository);

  final InventoryRepository _repository;

  Future<String> call() => _repository.exportJson();
}
