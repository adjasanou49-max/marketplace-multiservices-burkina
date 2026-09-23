import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class MarketplaceApp extends StatefulWidget {
  const MarketplaceApp({super.key});

  @override
  State<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends State<MarketplaceApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Supabase est initialisé dans main() avant runApp().
    // Le routeur doit donc être créé après ce bootstrap pour que
    // son listener auth puisse réellement s'abonner aux changements
    // de session.
    _router = createAppRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Marketplace Multiservices Burkina',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
