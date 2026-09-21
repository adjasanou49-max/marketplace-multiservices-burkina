import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    const environment = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final config = AppConfig(
      environment: environment,
      supabaseUrl: supabaseUrl.isEmpty ? null : supabaseUrl,
      supabaseAnonKey: supabaseAnonKey.isEmpty ? null : supabaseAnonKey,
    );

    if (config.supabaseUrl == null || config.supabaseAnonKey == null) {
      return;
    }

    await Supabase.initialize(
      url: config.supabaseUrl!,
      anonKey: config.supabaseAnonKey!,
    );
  }
}
