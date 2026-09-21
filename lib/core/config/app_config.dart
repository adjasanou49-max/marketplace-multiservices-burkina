class AppConfig {
  const AppConfig({
    required this.environment,
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.posthogApiKey,
    this.posthogHost,
  });

  final String environment;
  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String? posthogApiKey;
  final String? posthogHost;

  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';
}
