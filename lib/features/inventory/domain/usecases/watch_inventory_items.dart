import '../entities/inspection_item.dart';
import '../repositories/inventory_repository.dart';

/// Reactively watches the full inventory.
class WatchInventoryItems {
  const WatchInventoryItems(this._repository);

  final InventoryRepository _repository;

  Stream<List<InspectionItem>> call() => _repository.watchItems();
}
