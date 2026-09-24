import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceTokenRepository {
  const DeviceTokenRepository(this.client);

  final SupabaseClient client;

  Future<void> register({
    required String token,
    required String platform,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final normalizedToken = token.trim();
    final normalizedPlatform = platform.trim().toUpperCase();
    if (normalizedToken.isEmpty) {
      throw ArgumentError('Token push invalide.');
    }

    if (normalizedPlatform != 'ANDROID' && normalizedPlatform != 'IOS') {
      throw ArgumentError('Plateforme push invalide.');
    }

    await client.rpc(
      'register_notification_device',
      params: {
        'p_platform': normalizedPlatform,
        'p_push_token': normalizedToken,
      },
    );
  }

  Future<void> deactivate(String token) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non authentifié');
    }

    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) return;

    await client.rpc(
      'deactivate_notification_device',
      params: {
        'p_push_token': normalizedToken,
      },
    );
  }
}
