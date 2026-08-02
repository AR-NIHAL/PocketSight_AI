import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_item.dart';

InspectionItem _item({
  String id = 'i-1',
  String title = 'Plant',
  String category = 'Plant',
  String notes = '',
}) {
  final now = DateTime.utc(2026, 8, 2);
  return InspectionItem(
    id: id,
    title: title,
    category: category,
    markdownNotes: notes,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('InMemoryInventoryRepository', () {
    late InMemoryInventoryRepository repository;

    setUp(() {
      repository = InMemoryInventoryRepository();
    });

    test('saveItem emits through watchItems and upserts by id', () async {
      final emissions = <List<InspectionItem>>[];
      repository.watchItems().listen(emissions.add);

      await repository.saveItem(_item());
      await repository.saveItem(_item(title: 'Renamed'));

      expect(emissions, hasLength(2));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.single.title, 'Renamed');
    });

    test('deleteItem removes the item and emits', () async {
      final emissions = <List<InspectionItem>>[];
      repository.watchItems().listen(emissions.add);

      await repository.saveItem(_item());
      await repository.deleteItem('i-1');

      expect(emissions.last, isEmpty);
    });

    test('searchItems filters by query and category', () async {
      await repository.saveItem(_item(id: '1', title: 'Tomato', category: 'Plant'));
      await repository.saveItem(_item(id: '2', title: 'Shovel', category: 'Tool'));
      await repository.saveItem(_item(id: '3', title: 'Maple', category: 'Plant'));

      final plants = await repository.searchItems(category: 'plant');
      expect(plants.map((i) => i.id), ['1', '3']);

      final query = await repository.searchItems(query: 'shov');
      expect(query.map((i) => i.id), ['2']);

      final none = await repository.searchItems(query: 'zzz');
      expect(none, isEmpty);
    });

    test('exportJson round-trips through importJson', () async {
      await repository.saveItem(_item(id: '1', title: 'Tomato'));
      await repository.saveItem(_item(id: '2', title: 'Shovel'));

      final json = await repository.exportJson();
      final restored = InMemoryInventoryRepository();
      await restored.importJson(json);

      final items = await restored.searchItems();
      expect(items, hasLength(2));
      expect(items.first.title, 'Tomato');
    });

    test('importJson upserts matching ids', () async {
      await repository.saveItem(_item(id: '1', title: 'Old'));

      await repository.importJson(
        '[{"id":"1","title":"New","category":"Plant","markdownNotes":"",'
        '"thumbnailPath":null,"detectionLabel":null,"detectionConfidence":null,'
        '"schedule":null,"createdAt":"2026-08-02T00:00:00.000Z",'
        '"updatedAt":"2026-08-02T00:00:00.000Z"}]',
      );

      final items = await repository.searchItems();
      expect(items.single.title, 'New');
    });
  });
}
