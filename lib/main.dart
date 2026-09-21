import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/repository_providers.dart';

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
}
