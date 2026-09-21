import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Marketplace Multiservices Burkina',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
