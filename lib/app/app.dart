import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class MarketplaceApp extends StatefulWidget {
  const MarketplaceApp({super.key, this.bootstrapError});

  final Object? bootstrapError;

  @override
  State<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends State<MarketplaceApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapError == null) {
      _router = createAppRouter();
    }
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapError = widget.bootstrapError;
    if (bootstrapError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Marketplace Multiservices Burkina',
        theme: AppTheme.light,
        home: _BootstrapErrorPage(error: bootstrapError),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Marketplace Multiservices Burkina',
      theme: AppTheme.light,
      routerConfig: _router!,
    );
  }
}

class _BootstrapErrorPage extends StatelessWidget {
  const _BootstrapErrorPage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration requise'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Impossible de démarrer le backend de l’application.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Configurez SUPABASE_URL et '
                'SUPABASE_PUBLISHABLE_KEY puis redémarrez l’application.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}