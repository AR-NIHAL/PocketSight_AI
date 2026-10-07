class Device {
  final String id;
  final String brand;
  final String model;
  final String? serialNumber;
  final bool isSerialVerified;
  final String? missingSerialReason;
  final String? specs;

  const Device({
    required this.id,
    required this.brand,
    required this.model,
    this.serialNumber,
    this.isSerialVerified = false,
    this.missingSerialReason,
    this.specs,
  });

  String get displayName => '$brand $model'.trim();

  String get displaySerial =>
      (serialNumber != null && serialNumber!.trim().isNotEmpty)
          ? serialNumber!
          : (missingSerialReason ?? 'No Serial (Missing/Unreadable)');

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand': brand,
        'model': model,
        'serialNumber': serialNumber,
        'isSerialVerified': isSerialVerified,
        'missingSerialReason': missingSerialReason,
        'specs': specs,
      };

  factory Device.fromMap(Map<String, dynamic> map) => Device(
        id: map['id'] as String,
        brand: map['brand'] as String,
        model: map['model'] as String,
        serialNumber: map['serialNumber'] as String?,
        isSerialVerified: map['isSerialVerified'] as bool? ?? false,
        missingSerialReason: map['missingSerialReason'] as String?,
        specs: map['specs'] as String?,
      );

  Device copyWith({
    String? id,
    String? brand,
    String? model,
    String? serialNumber,
    bool? isSerialVerified,
    String? missingSerialReason,
    String? specs,
  }) {
    return Device(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      isSerialVerified: isSerialVerified ?? this.isSerialVerified,
      missingSerialReason: missingSerialReason ?? this.missingSerialReason,
      specs: specs ?? this.specs,
    );
  }
}
