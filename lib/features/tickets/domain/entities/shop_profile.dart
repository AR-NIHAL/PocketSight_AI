class ShopProfile {
  final String shopName;
  final String phone;
  final String address;
  final String termsNote;

  const ShopProfile({
    this.shopName = 'Laptop Repair Lab',
    this.phone = '+880 1700-000000',
    this.address = 'Shop #12, Computer City, Dhaka',
    this.termsNote =
        'Please bring this ticket receipt during device collection. Diagnosis fee applies for unrepairable devices.',
  });

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'phone': phone,
        'address': address,
        'termsNote': termsNote,
      };

  factory ShopProfile.fromMap(Map<String, dynamic> map) => ShopProfile(
        shopName: map['shopName'] as String? ?? 'Laptop Repair Lab',
        phone: map['phone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        termsNote: map['termsNote'] as String? ?? '',
      );

  ShopProfile copyWith({
    String? shopName,
    String? phone,
    String? address,
    String? termsNote,
  }) {
    return ShopProfile(
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      termsNote: termsNote ?? this.termsNote,
    );
  }
}
