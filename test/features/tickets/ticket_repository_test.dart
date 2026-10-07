import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/customer.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/delivery_record.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/device.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/intake_details.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/repair_ticket.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/ticket_status.dart';

import '../../helpers/in_memory_ticket_repository.dart';

void main() {
  group('TicketRepository & Lifecycle', () {
    late InMemoryTicketRepository repo;

    setUp(() {
      repo = InMemoryTicketRepository();
    });

    test('saves ticket, updates status with work note, and completes handover', () async {
      final ticket = RepairTicket(
        id: 'ticket-1',
        ticketNumber: 'REP-2610-001',
        customer: Customer(
          id: 'c1',
          name: 'Nihal',
          phone: '01800000000',
          createdAt: DateTime.now(),
        ),
        device: const Device(
          id: 'd1',
          brand: 'Lenovo',
          model: 'ThinkPad T480',
          serialNumber: 'PF2ABC12',
          isSerialVerified: true,
        ),
        reportedIssue: 'Keyboard not working',
        intakeDetails: const IntakeDetails(
          physicalCondition: 'Good condition',
          suppliedAccessories: ['Charger / Adapter'],
        ),
        status: TicketStatus.received,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save ticket
      await repo.saveTicket(ticket);
      expect(await repo.getTicketById('ticket-1'), isNotNull);

      // Advance to In Progress with note
      await repo.updateTicketStatus(
        ticketId: 'ticket-1',
        newStatus: TicketStatus.inProgress,
        workNote: 'Replaced internal keyboard ribbon cable.',
        technicianName: 'Rafiq',
      );

      var updated = await repo.getTicketById('ticket-1');
      expect(updated?.status, TicketStatus.inProgress);
      expect(updated?.workLogs.length, 1);
      expect(updated?.workLogs.first.note, contains('ribbon cable'));
      expect(updated?.workLogs.first.technicianName, 'Rafiq');

      // Complete Handover to customer
      await repo.completeHandover(
        ticketId: 'ticket-1',
        deliveryRecord: DeliveryRecord(
          deliveredAt: DateTime.now(),
          isRepaired: true,
          returnedAccessories: ['Charger / Adapter'],
          receiverName: 'Nihal',
          amountPaid: 1500.0,
        ),
      );

      updated = await repo.getTicketById('ticket-1');
      expect(updated?.status, TicketStatus.delivered);
      expect(updated?.deliveryRecord?.isRepaired, isTrue);
      expect(updated?.deliveryRecord?.returnedAccessories, ['Charger / Adapter']);
    });

    test('retrieves repair history by device serial number', () async {
      final t1 = RepairTicket(
        id: 't1',
        ticketNumber: 'REP-2610-001',
        customer: Customer(id: 'c1', name: 'Nihal', phone: '018', createdAt: DateTime.now()),
        device: const Device(id: 'd1', brand: 'HP', model: 'Pavilion', serialNumber: '5CD1234XYZ'),
        reportedIssue: 'Fan noise',
        intakeDetails: const IntakeDetails(physicalCondition: '', suppliedAccessories: []),
        status: TicketStatus.delivered,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      final t2 = RepairTicket(
        id: 't2',
        ticketNumber: 'REP-2610-045',
        customer: Customer(id: 'c1', name: 'Nihal', phone: '018', createdAt: DateTime.now()),
        device: const Device(id: 'd1', brand: 'HP', model: 'Pavilion', serialNumber: '5CD1234XYZ'),
        reportedIssue: 'SSD upgrade',
        intakeDetails: const IntakeDetails(physicalCondition: '', suppliedAccessories: []),
        status: TicketStatus.received,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveTicket(t1);
      await repo.saveTicket(t2);

      final history = await repo.getTicketsByDeviceSerial('5CD1234XYZ');
      expect(history.length, 2);
    });
  });
}
