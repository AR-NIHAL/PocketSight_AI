import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/core/utils/ticket_number_generator.dart';

void main() {
  group('TicketNumberGenerator', () {
    test('formats sequence correctly with current year and month', () {
      final date = DateTime(2026, 10, 7);
      final num1 = TicketNumberGenerator.generate(sequenceNumber: 1, now: date);
      expect(num1, 'REP-2610-001');

      final num42 = TicketNumberGenerator.generate(sequenceNumber: 42, now: date);
      expect(num42, 'REP-2610-042');

      final num125 = TicketNumberGenerator.generate(sequenceNumber: 125, now: date);
      expect(num125, 'REP-2610-125');
    });
  });
}
