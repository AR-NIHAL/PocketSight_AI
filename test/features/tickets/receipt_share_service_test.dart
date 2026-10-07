import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/features/tickets/data/services/receipt_share_service.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/customer.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/device.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/intake_details.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/repair_ticket.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/shop_profile.dart';
import 'package:pocketsite_ai/features/tickets/domain/entities/ticket_status.dart';

void main() {
  test('generateReceiptText includes shop header, customer, device and accessories', () {
    final ticket = RepairTicket(
      id: '1',
      ticketNumber: 'REP-2610-001',
      customer: Customer(
        id: 'c1',
        name: 'Tanvir Ahmed',
        phone: '01711223344',
        createdAt: DateTime(2026, 10, 7),
      ),
      device: const Device(
        id: 'd1',
        brand: 'Dell',
        model: 'Inspiron 15',
        serialNumber: '7B3K9X2',
        isSerialVerified: true,
      ),
      reportedIssue: 'Display flickering on battery power',
      intakeDetails: const IntakeDetails(
        physicalCondition: 'Minor scratches on back lid',
        suppliedAccessories: ['Charger / Adapter', 'Laptop Bag / Sleeve'],
      ),
      status: TicketStatus.received,
      createdAt: DateTime(2026, 10, 7, 14, 30),
      updatedAt: DateTime(2026, 10, 7, 14, 30),
    );

    const profile = ShopProfile(
      shopName: 'FastFix Laptops',
      phone: '01900000000',
      address: 'Dhaka',
      termsNote: 'Please keep this receipt.',
    );

    final receipt = ReceiptShareService.generateReceiptText(
      ticket: ticket,
      profile: profile,
    );

    expect(receipt, contains('FASTFIX LAPTOPS'));
    expect(receipt, contains('REP-2610-001'));
    expect(receipt, contains('Tanvir Ahmed'));
    expect(receipt, contains('01711223344'));
    expect(receipt, contains('Dell Inspiron 15'));
    expect(receipt, contains('7B3K9X2 [Verified]'));
    expect(receipt, contains('Display flickering on battery power'));
    expect(receipt, contains('• Charger / Adapter'));
    expect(receipt, contains('• Laptop Bag / Sleeve'));
    expect(receipt, contains('Please keep this receipt.'));
  });
}
