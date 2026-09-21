import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get key {
    if (publishableKey.isNotEmpty) return publishableKey;
    return legacyAnonKey;
  }

  static bool get isConfigured => url.isNotEmpty && key.isNotEmpty;

  static Future<SupabaseClient?> initialize() async {
    if (!isConfigured) return null;

    await Supabase.initialize(
      url: url,
      publishableKey: key,
      debug: false,
    );
    return Supabase.instance.client;
  }
}
