class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.recipientName,
    this.label,
    this.phone,
    this.addressLine,
    this.city,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });
  final String id;
  final String recipientName;
  final String? label;
  final String? phone;
  final String? addressLine;
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  factory DeliveryAddress.fromMap(Map<String, dynamic> m) => DeliveryAddress(
    id: m['id'] as String,
    recipientName: m['recipient_name'] as String? ?? '',
    label: m['label'] as String?,
    phone: m['phone'] as String?,
    addressLine: m['address_line'] as String?,
    city: m['city'] as String?,
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    isDefault: m['is_default'] as bool? ?? false,
  );
}
