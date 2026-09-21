import 'package:flutter/material.dart';

import 'app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const ProviderScope(child: MarketplaceApp()));
}
