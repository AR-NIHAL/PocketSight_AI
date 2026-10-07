class TicketNumberGenerator {
  /// Generates a sequential ticket number like `REP-2610-001`.
  static String generate({
    required int sequenceNumber,
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final year = (date.year % 100).toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final seq = sequenceNumber.toString().padLeft(3, '0');
    return 'REP-$year$month-$seq';
  }
}
