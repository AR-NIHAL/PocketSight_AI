import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/customer.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/device.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/intake_details.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/repair_ticket.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/ticket_status.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/work_log_entry.dart';
import 'package:pocketsite_ai/features/tickets/presentation/providers/ticket_providers.dart';
import 'package:pocketsite_ai/features/tickets/presentation/screens/ticket_detail_screen.dart';

import '../../helpers/in_memory_ticket_repository.dart';

void main() {
  testWidgets('TicketDetailScreen renders Screen 06 UI elements accurately',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = InMemoryTicketRepository();
    final testTicket = RepairTicket(
      id: 'ticket-17',
      ticketNumber: 'REP-2610-0017',
      customer: Customer(
        id: 'cust-1',
        name: 'Rahim',
        phone: '0123 456 7890',
        createdAt: DateTime.now(),
      ),
      device: const Device(
        id: 'dev-1',
        brand: 'DemoBrand',
        model: 'DemoBook 14',
        serialNumber: '7B3K9X2',
        isSerialVerified: true,
      ),
      reportedIssue: 'No display, fan running',
      intakeDetails: const IntakeDetails(
        physicalCondition: 'Scratches on lid',
        suppliedAccessories: ['Charger', 'Bag'],
        photoPaths: [],
      ),
      status: TicketStatus.ready,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      workLogs: [
        WorkLogEntry(
          id: 'log-1',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          note: 'Device received for diagnosis.',
          statusChange: TicketStatus.received,
        ),
        WorkLogEntry(
          id: 'log-2',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          note: 'Display cable replaced. Screen functioning normally.',
          statusChange: TicketStatus.ready,
          technicianName: 'Sufian',
        ),
      ],
      estimatedCost: 2500,
      storageLocation: 'Shelf B-3',
    );

    await repo.saveTicket(testTicket);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ticketRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: TicketDetailScreen(ticketId: 'ticket-17'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Short Ticket Number in App Bar (R-0017)
    expect(find.text('R-0017'), findsOneWidget);

    // Verify Status Pill in App Bar (Ready)
    expect(find.text('Ready'), findsWidgets);

    // Verify Device Card
    expect(find.text('DemoBrand DemoBook 14'), findsOneWidget);
    expect(find.text('S/N: 7B3K9X2'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);

    // Verify Customer Row
    expect(find.text('Rahim'), findsOneWidget);
    expect(find.text('0123 456 7890'), findsOneWidget);

    // Verify Metadata Rows
    expect(find.text('COMPLAINT'), findsOneWidget);
    expect(find.text('No display, fan running'), findsOneWidget);
    expect(find.text('RECEIVED WITH'), findsOneWidget);
    expect(find.text('Charger, Bag'), findsOneWidget);
    expect(find.text('CONDITION'), findsOneWidget);
    expect(find.text('Scratches on lid'), findsOneWidget);

    // Verify Photos row
    expect(find.text('Photos'), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);

    // Verify Activity Timeline
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Device received for diagnosis.'), findsOneWidget);
    expect(find.text('Display cable replaced. Screen functioning normally.'), findsOneWidget);
    expect(find.text('Tech: Sufian'), findsOneWidget);

    // Verify Bottom Actions: Share receipt & Mark delivered
    expect(find.text('Share receipt'), findsOneWidget);
    expect(find.text('Mark delivered'), findsOneWidget);
  });
}
