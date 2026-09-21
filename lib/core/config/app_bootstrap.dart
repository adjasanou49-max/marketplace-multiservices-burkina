import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    const environment = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    final config = AppConfig(
      environment: environment,
      supabaseUrl: supabaseUrl.isEmpty ? null : supabaseUrl,
      supabasePublishableKey: publishableKey.isEmpty ? null : publishableKey,
    );

    if (config.supabaseUrl == null || config.supabasePublishableKey == null) {
      return;
    }

    await Supabase.initialize(
      url: config.supabaseUrl!,
      publishableKey: config.supabasePublishableKey!,
    );
  }
}
