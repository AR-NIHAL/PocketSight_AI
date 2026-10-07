import 'ticket_status.dart';

class WorkLogEntry {
  final String id;
  final DateTime timestamp;
  final String note;
  final TicketStatus? statusChange;
  final String? technicianName;

  const WorkLogEntry({
    required this.id,
    required this.timestamp,
    required this.note,
    this.statusChange,
    this.technicianName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
        'statusChange': statusChange?.name,
        'technicianName': technicianName,
      };

  factory WorkLogEntry.fromMap(Map<String, dynamic> map) => WorkLogEntry(
        id: map['id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        note: map['note'] as String,
        statusChange: map['statusChange'] != null
            ? TicketStatus.values.byName(map['statusChange'] as String)
            : null,
        technicianName: map['technicianName'] as String?,
      );
}
