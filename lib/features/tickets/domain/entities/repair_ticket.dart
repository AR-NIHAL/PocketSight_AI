import 'customer.dart';
import 'delivery_record.dart';
import 'device.dart';
import 'intake_details.dart';
import 'ticket_status.dart';
import 'work_log_entry.dart';

class RepairTicket {
  final String id;
  final String ticketNumber;
  final Customer customer;
  final Device device;
  final String reportedIssue;
  final IntakeDetails intakeDetails;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkLogEntry> workLogs;
  final DeliveryRecord? deliveryRecord;
  final double? estimatedCost;
  final double? finalCost;
  final String? storageLocation;

  const RepairTicket({
    required this.id,
    required this.ticketNumber,
    required this.customer,
    required this.device,
    required this.reportedIssue,
    required this.intakeDetails,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.workLogs = const [],
    this.deliveryRecord,
    this.estimatedCost,
    this.finalCost,
    this.storageLocation,
  });

  bool get isClosed =>
      status == TicketStatus.delivered ||
      status == TicketStatus.closedWithoutRepair;

  String get shortTicketNumber {
    final parts = ticketNumber.split('-');
    if (parts.length >= 3) {
      return 'R-${parts.last.padLeft(4, '0')}';
    } else if (ticketNumber.startsWith('REP-')) {
      return ticketNumber.replaceFirst('REP-', 'R-');
    }
    return ticketNumber;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ticketNumber': ticketNumber,
        'customer': customer.toMap(),
        'device': device.toMap(),
        'reportedIssue': reportedIssue,
        'intakeDetails': intakeDetails.toMap(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'workLogs': workLogs.map((w) => w.toMap()).toList(),
        'deliveryRecord': deliveryRecord?.toMap(),
        'estimatedCost': estimatedCost,
        'finalCost': finalCost,
        'storageLocation': storageLocation,
      };

  factory RepairTicket.fromMap(Map<String, dynamic> map) => RepairTicket(
        id: map['id'] as String,
        ticketNumber: map['ticketNumber'] as String,
        customer: Customer.fromMap(map['customer'] as Map<String, dynamic>),
        device: Device.fromMap(map['device'] as Map<String, dynamic>),
        reportedIssue: map['reportedIssue'] as String? ?? '',
        intakeDetails: IntakeDetails.fromMap(
            map['intakeDetails'] as Map<String, dynamic>? ?? {}),
        status: TicketStatus.values.byName(map['status'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        workLogs: (map['workLogs'] as List? ?? [])
            .map((w) => WorkLogEntry.fromMap(w as Map<String, dynamic>))
            .toList(),
        deliveryRecord: map['deliveryRecord'] != null
            ? DeliveryRecord.fromMap(
                map['deliveryRecord'] as Map<String, dynamic>)
            : null,
        estimatedCost: (map['estimatedCost'] as num?)?.toDouble(),
        finalCost: (map['finalCost'] as num?)?.toDouble(),
        storageLocation: map['storageLocation'] as String?,
      );

  RepairTicket copyWith({
    String? id,
    String? ticketNumber,
    Customer? customer,
    Device? device,
    String? reportedIssue,
    IntakeDetails? intakeDetails,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkLogEntry>? workLogs,
    DeliveryRecord? deliveryRecord,
    double? estimatedCost,
    double? finalCost,
    String? storageLocation,
  }) {
    return RepairTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      customer: customer ?? this.customer,
      device: device ?? this.device,
      reportedIssue: reportedIssue ?? this.reportedIssue,
      intakeDetails: intakeDetails ?? this.intakeDetails,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workLogs: workLogs ?? this.workLogs,
      deliveryRecord: deliveryRecord ?? this.deliveryRecord,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      finalCost: finalCost ?? this.finalCost,
      storageLocation: storageLocation ?? this.storageLocation,
    );
  }
}
