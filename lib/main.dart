import 'package:flutter/material.dart';

import 'app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? bootstrapError;
  try {
    await AppBootstrap.initialize();
  } catch (error) {
    bootstrapError = error;
  }

  runApp(
    ProviderScope(
      child: MarketplaceApp(bootstrapError: bootstrapError),
    ),
  );
}
