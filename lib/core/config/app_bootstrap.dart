import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/secure_supabase_local_storage.dart';
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

    final missing = <String>[
      if (config.supabaseUrl == null) 'SUPABASE_URL',
      if (config.supabasePublishableKey == null) 'SUPABASE_PUBLISHABLE_KEY',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Configuration Supabase manquante : ${missing.join(', ')}. '
        'Fournissez ces valeurs avec --dart-define ou '
        '--dart-define-from-file avant de lancer l’application.',
      );
    }

    final parsedUrl = Uri.tryParse(config.supabaseUrl!);
    if (parsedUrl == null ||
        parsedUrl.host.isEmpty ||
        parsedUrl.scheme != 'https') {
      throw StateError(
        'SUPABASE_URL est invalide : utilisez une URL HTTPS Supabase.',
      );
    }

    await Supabase.initialize(
      url: config.supabaseUrl!,
      publishableKey: config.supabasePublishableKey!,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureSupabaseLocalStorage(),
        persistSession: true,
      ),
    );
  }
}
