class Customer {
  final String id;
  final String name;
  final String phone;
  final String? alternatePhone;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.alternatePhone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'alternatePhone': alternatePhone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String,
        alternatePhone: map['alternatePhone'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? alternatePhone,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
