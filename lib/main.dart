import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/repository_providers.dart';
import 'core/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = await SupabaseConfig.initialize();

  runApp(
    ProviderScope(
      overrides: [
        supabaseProvider.overrideWithValue(client),
      ],
      child: const MarketplaceApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.instance.initialize(client);
  });
}
