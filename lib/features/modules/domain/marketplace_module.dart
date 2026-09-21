class MarketplaceModule {
  const MarketplaceModule({
    required this.key,
    required this.label,
    required this.route,
    this.iconName,
    this.config = const {},
  });

  final String key;
  final String label;
  final String route;
  final String? iconName;
  final Map<String, dynamic> config;

  factory MarketplaceModule.fromMap(Map<String, dynamic> map) {
    final rawConfig = map['config'];
    return MarketplaceModule(
      key: map['key'] as String,
      label: map['label'] as String? ?? map['key'].toString(),
      route: map['route'] as String? ?? '/',
      iconName: map['icon_name'] as String?,
      config: rawConfig is Map
          ? Map<String, dynamic>.from(rawConfig)
          : const {},
    );
  }
}
