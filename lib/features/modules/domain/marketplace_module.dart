class MarketplaceModule {
  const MarketplaceModule({
    required this.key,
    required this.label,
    required this.route,
    required this.iconName,
    required this.enabled,
    required this.sortOrder,
    required this.config,
  });

  final String key;
  final String label;
  final String route;
  final String? iconName;
  final bool enabled;
  final int sortOrder;
  final Map<String, dynamic> config;

  factory MarketplaceModule.fromMap(Map<String, dynamic> map) {
    final rawConfig = map['config'];

    return MarketplaceModule(
      key: map['key']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      route: map['route']?.toString() ?? '/',
      iconName: map['icon_name']?.toString(),
      enabled: map['enabled'] == true,
      sortOrder: int.tryParse(map['sort_order']?.toString() ?? '') ?? 0,
      config: rawConfig is Map
          ? Map<String, dynamic>.from(rawConfig)
          : const <String, dynamic>{},
    );
  }
}
