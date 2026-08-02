import '../entities/inspection_item.dart';
import '../repositories/inventory_repository.dart';

/// Searches/filters the inventory by free-text [query] and/or [category].
class SearchInventoryItems {
  const SearchInventoryItems(this._repository);

  final InventoryRepository _repository;

  Future<List<InspectionItem>> call({String? query, String? category}) =>
      _repository.searchItems(query: query, category: category);
}
