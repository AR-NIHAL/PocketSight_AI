import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pocketsite_ai/features/inventory/data/providers.dart';
import 'package:pocketsite_ai/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:pocketsite_ai/features/inventory/domain/entities/inspection_item.dart';
import 'package:pocketsite_ai/features/inventory/presentation/screens/inspection_item_detail_screen.dart';
import 'package:pocketsite_ai/features/inventory/presentation/screens/inventory_screen.dart';

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

Widget _harness(InMemoryInventoryRepository repo) {
  final router = GoRouter(
    initialLocation: '/inventory',
    routes: [
      GoRoute(
        path: '/inventory',
        builder: (_, _) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (_, state) => InspectionItemDetailScreen(
          item: state.extra! as InspectionItem,
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [inventoryRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows an empty state, then renders saved items reactively',
      (tester) async {
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    expect(find.text('No items yet'), findsOneWidget);

    await repo.saveItem(_item(id: '1', title: 'Tomato'));
    await repo.saveItem(_item(id: '2', title: 'Shovel', category: 'Tool'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Shovel'), findsOneWidget);
    expect(find.text('No items yet'), findsNothing);
  });

  testWidgets('filters the grid by search query', (tester) async {
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await repo.saveItem(_item(id: '1', title: 'Tomato', category: 'Plant'));
    await repo.saveItem(_item(id: '2', title: 'Shovel', category: 'Tool'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'tom');
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Shovel'), findsNothing);
  });

  testWidgets('filters the grid by category chip', (tester) async {
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await repo.saveItem(_item(id: '1', title: 'Tomato', category: 'Plant'));
    await repo.saveItem(_item(id: '2', title: 'Shovel', category: 'Tool'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tool'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsNothing);
    expect(find.text('Shovel'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Shovel'), findsOneWidget);
  });

  testWidgets('shows a no-match state when nothing matches the filter',
      (tester) async {
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await repo.saveItem(_item(id: '1', title: 'Tomato'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No matching items'), findsOneWidget);
  });

  testWidgets('navigates to the item detail screen when a card is tapped',
      (tester) async {
    final repo = InMemoryInventoryRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await repo.saveItem(
      _item(id: '1', title: 'Tomato', notes: '**Height**: 12cm'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tomato'));
    await tester.pumpAndSettle();

    expect(find.byType(InspectionItemDetailScreen), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });
}
