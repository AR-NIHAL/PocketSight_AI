import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/core/presentation/app_shell.dart';
import 'package:pocketsite_ai/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:pocketsite_ai/features/tickets/presentation/screens/new_ticket_screen.dart';
import 'package:pocketsite_ai/main.dart';

import 'helpers/in_memory_ticket_repository.dart';

void main() {
  testWidgets('App boots and renders Repair Intake dashboard matching Screen 01',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = InMemoryTicketRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(repo),
        ],
        child: const RepairIntakeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);

    // Verify 3 bottom navigation destinations
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify app bar title and subtitle from Screen 01
    expect(find.text('Repair Intake'), findsOneWidget);
    expect(find.text('Workshop tickets'), findsOneWidget);

    // Verify search hint text
    expect(find.text('Search ticket, customer or serial'), findsOneWidget);

    // Verify filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);

    // Verify "+ New repair" button is present
    expect(find.text('+ New repair'), findsOneWidget);

    // Tap "+ New repair" and verify navigation to NewTicketScreen
    await tester.tap(find.text('+ New repair'));
    await tester.pumpAndSettle();

    expect(find.byType(NewTicketScreen), findsOneWidget);
    expect(find.text('New repair'), findsOneWidget);
    expect(find.text('Customer name'), findsOneWidget);
    expect(find.text('Scan device label'), findsOneWidget);
    expect(find.text('No serial number'), findsOneWidget);
    expect(find.text('Complaint'), findsOneWidget);
    expect(find.text('Accessories'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
