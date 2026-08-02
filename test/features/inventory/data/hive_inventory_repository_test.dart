import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:pocketsite_ai/features/inventory/data/repositories/hive_inventory_repository.dart';
import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_item.dart';

InspectionItem _item({
  required String id,
  required String title,
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
  late Directory tempDir;
  var boxCounter = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_inventory_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  String freshBoxName() => 'inventory_${boxCounter++}';

  group('HiveInventoryRepository', () {
    test('emits the current snapshot on subscribe', () async {
      final repo = HiveInventoryRepository(boxName: freshBoxName());
      await repo.saveItem(_item(id: '1', title: 'Tomato'));

      final snapshot = await repo.watchItems().first;

      expect(snapshot.map((i) => i.title), ['Tomato']);
    });

    test('upserts by id and emits on every mutation', () async {
      final repo = HiveInventoryRepository(boxName: freshBoxName());
      final emissions = <List<InspectionItem>>[];
      repo.watchItems().listen(emissions.add);

      await repo.saveItem(_item(id: '1', title: 'Before'));
      await repo.saveItem(_item(id: '1', title: 'After'));

      // Broadcast events are delivered asynchronously; flush the event queue
      // until every pending snapshot has been received.
      await pumpEventQueue();

      expect(emissions.last.map((i) => i.title), ['After']);
    });

    test('deleteItem removes the item', () async {
      final repo = HiveInventoryRepository(boxName: freshBoxName());
      await repo.saveItem(_item(id: '1', title: 'A'));
      await repo.saveItem(_item(id: '2', title: 'B'));

      await repo.deleteItem('1');

      final items = await repo.searchItems();
      expect(items.map((i) => i.id), ['2']);
    });

    test('searchItems filters by query and category', () async {
      final repo = HiveInventoryRepository(boxName: freshBoxName());
      await repo.saveItem(_item(id: '1', title: 'Tomato', category: 'Plant'));
      await repo.saveItem(_item(id: '2', title: 'Shovel', category: 'Tool'));
      await repo.saveItem(_item(id: '3', title: 'Maple', category: 'Plant'));

      final plants = await repo.searchItems(category: 'plant');
      expect(plants.map((i) => i.id), ['1', '3']);

      final query = await repo.searchItems(query: 'shov');
      expect(query.map((i) => i.id), ['2']);

      final none = await repo.searchItems(query: 'zzz');
      expect(none, isEmpty);
    });

    test('persists across repository instances with the same box', () async {
      const boxName = 'persistent_box';
      final writer = HiveInventoryRepository(boxName: boxName);
      await writer.saveItem(_item(id: '1', title: 'Survives'));

      final reader = HiveInventoryRepository(boxName: boxName);
      final items = await reader.searchItems();

      expect(items.map((i) => i.title), ['Survives']);
    });

    test('exportJson round-trips through importJson', () async {
      final repo = HiveInventoryRepository(boxName: freshBoxName());
      await repo.saveItem(_item(id: '1', title: 'Tomato'));
      await repo.saveItem(_item(id: '2', title: 'Shovel', category: 'Tool'));

      final json = await repo.exportJson();
      final restored = HiveInventoryRepository(boxName: freshBoxName());
      await restored.importJson(json);

      final items = await restored.searchItems();
      expect(items, hasLength(2));
      expect(items.map((i) => i.title), contains('Tomato'));
      expect(items.map((i) => i.title), contains('Shovel'));
    });

    test('importJson upserts matching ids', () async {
      final repo = HiveInventoryRepository(boxName: freshBoxName());
      await repo.saveItem(_item(id: '1', title: 'Old'));

      await repo.importJson(
        '[{"id":"1","title":"New","category":"Plant","markdownNotes":"",'
        '"thumbnailPath":null,"detectionLabel":null,"detectionConfidence":null,'
        '"schedule":null,"createdAt":"2026-08-02T00:00:00.000Z",'
        '"updatedAt":"2026-08-02T00:00:00.000Z"}]',
      );

      final items = await repo.searchItems();
      expect(items.single.title, 'New');
    });
  });
}
