class DeliveryRecord {
  final DateTime deliveredAt;
  final bool isRepaired;
  final String? unrepairedReason;
  final List<String> returnedAccessories;
  final String receiverName;
  final String? handoverNotes;
  final double? amountPaid;

  const DeliveryRecord({
    required this.deliveredAt,
    required this.isRepaired,
    this.unrepairedReason,
    required this.returnedAccessories,
    required this.receiverName,
    this.handoverNotes,
    this.amountPaid,
  });

  Map<String, dynamic> toMap() => {
        'deliveredAt': deliveredAt.toIso8601String(),
        'isRepaired': isRepaired,
        'unrepairedReason': unrepairedReason,
        'returnedAccessories': returnedAccessories,
        'receiverName': receiverName,
        'handoverNotes': handoverNotes,
        'amountPaid': amountPaid,
      };

  factory DeliveryRecord.fromMap(Map<String, dynamic> map) => DeliveryRecord(
        deliveredAt: DateTime.parse(map['deliveredAt'] as String),
        isRepaired: map['isRepaired'] as bool? ?? true,
        unrepairedReason: map['unrepairedReason'] as String?,
        returnedAccessories:
            List<String>.from(map['returnedAccessories'] as List? ?? []),
        receiverName: map['receiverName'] as String? ?? 'Customer',
        handoverNotes: map['handoverNotes'] as String?,
        amountPaid: (map['amountPaid'] as num?)?.toDouble(),
      );
}
