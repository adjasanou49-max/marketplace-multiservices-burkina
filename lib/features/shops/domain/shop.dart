class Shop {
  const Shop({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverUrl,
    this.description,
    this.status,
    this.verificationStatus,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? coverUrl;
  final String? description;
  final String? status;
  final String? verificationStatus;

  factory Shop.fromMap(Map<String, dynamic> map) => Shop(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        logoUrl: map['logo_url'] as String?,
        coverUrl: map['cover_url'] as String?,
        description: map['description'] as String?,
        status: map['status'] as String?,
        verificationStatus: map['verification_status'] as String?,
      );
}
