import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_item.dart';
import 'package:pocketsite_ai/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:pocketsite_ai/features/inventory/domain/usecases/delete_inspection_item.dart';
import 'package:pocketsite_ai/features/inventory/domain/usecases/export_inventory.dart';
import 'package:pocketsite_ai/features/inventory/domain/usecases/import_inventory.dart';
import 'package:pocketsite_ai/features/inventory/domain/usecases/save_inspection_item.dart';
import 'package:pocketsite_ai/features/inventory/domain/usecases/search_inventory_items.dart';
import 'package:pocketsite_ai/features/inventory/domain/usecases/watch_inventory_items.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockInventoryRepository repository;
  final now = DateTime.utc(2026, 1, 1);

  setUp(() {
    repository = MockInventoryRepository();
  });

  test('WatchInventoryItems forwards the reactive stream', () async {
    final useCase = WatchInventoryItems(repository);
    final items = [
      InspectionItem(
        id: 'id-1',
        title: 'Monstera',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    when(() => repository.watchItems())
        .thenAnswer((_) => Stream.value(items));

    expect(await useCase().toList(), [items]);
    verify(() => repository.watchItems()).called(1);
  });

  test('SaveInspectionItem forwards the item', () async {
    final useCase = SaveInspectionItem(repository);
    final item = InspectionItem(
      id: 'id-1',
      title: 'Monstera',
      createdAt: now,
      updatedAt: now,
    );
    when(() => repository.saveItem(item)).thenAnswer((_) async {});

    await useCase(item);

    verify(() => repository.saveItem(item)).called(1);
  });

  test('DeleteInspectionItem forwards the id', () async {
    final useCase = DeleteInspectionItem(repository);
    when(() => repository.deleteItem('id-1')).thenAnswer((_) async {});

    await useCase('id-1');

    verify(() => repository.deleteItem('id-1')).called(1);
  });

  test('SearchInventoryItems forwards query and category', () async {
    final useCase = SearchInventoryItems(repository);
    when(() => repository.searchItems(query: 'mon', category: 'Plants'))
        .thenAnswer((_) async => []);
    when(() => repository.searchItems(query: null, category: null))
        .thenAnswer((_) async => []);

    await useCase(query: 'mon', category: 'Plants');
    await useCase();

    verify(() => repository.searchItems(query: 'mon', category: 'Plants'))
        .called(1);
    verify(() => repository.searchItems(query: null, category: null)).called(1);
  });

  test('ExportInventory returns the serialized JSON', () async {
    final useCase = ExportInventory(repository);
    when(() => repository.exportJson()).thenAnswer((_) async => '{"items":[]}');

    final json = await useCase();

    expect(json, '{"items":[]}');
    verify(() => repository.exportJson()).called(1);
  });

  test('ImportInventory forwards the JSON string', () async {
    final useCase = ImportInventory(repository);
    when(() => repository.importJson('{"items":[]}')).thenAnswer((_) async {});

    await useCase('{"items":[]}');

    verify(() => repository.importJson('{"items":[]}')).called(1);
  });
}
