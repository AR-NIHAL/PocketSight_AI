import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketsite_ai/features/inventory/data/providers.dart';
import 'package:pocketsite_ai/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_item.dart';
import 'package:pocketsite_ai/features/inventory/presentation/screens/inspection_item_detail_screen.dart';

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

Widget _harness(InMemoryInventoryRepository repo, InspectionItem item) {
  return ProviderScope(
    overrides: [inventoryRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InspectionItemDetailScreen(item: item),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDetail(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders title, category and rendered markdown notes',
      (tester) async {
    _useTallViewport(tester);
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(
      _harness(repo, _item(id: '1', title: 'Tomato', notes: '**Height**: 12cm')),
    );
    await _openDetail(tester);

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Plant'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.textContaining('12cm', findRichText: true), findsOneWidget);
  });

  testWidgets('shows a no-notes hint when notes are empty', (tester) async {
    _useTallViewport(tester);
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo, _item(id: '1', title: 'Shovel')));
    await _openDetail(tester);

    expect(find.text('No notes'), findsOneWidget);
  });

  testWidgets('edits the item and persists the change', (tester) async {
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo, _item(id: '1', title: 'Tomato')));
    await _openDetail(tester);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tomato'),
      'Heirloom Tomato',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final items = await repo.searchItems();
    expect(items.single.title, 'Heirloom Tomato');
    expect(find.text('Heirloom Tomato'), findsOneWidget);
  });

  testWidgets('deletes the item after confirmation', (tester) async {
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo, _item(id: '1', title: 'Tomato')));
    await _openDetail(tester);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Remove'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(InspectionItemDetailScreen), findsNothing);
    expect(await repo.searchItems(), isEmpty);
  });
}
