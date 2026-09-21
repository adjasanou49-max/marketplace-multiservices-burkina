class AppConfig {
  const AppConfig({
    required this.environment,
    this.supabaseUrl,
    this.supabasePublishableKey,
    this.posthogApiKey,
    this.posthogHost,
  });

  final String environment;
  final String? supabaseUrl;
  final String? supabasePublishableKey;
  final String? posthogApiKey;
  final String? posthogHost;

  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';
}
