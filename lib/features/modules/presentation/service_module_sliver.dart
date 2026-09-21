import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/module_controller.dart';
import '../domain/marketplace_module.dart';

class ServiceModuleSliver extends ConsumerWidget {
  const ServiceModuleSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(enabledModulesProvider);

    return state.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox(height: 0)),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox(height: 0)),
      data: (modules) {
        final visible = modules
            .where((module) => _supportedRoutes.contains(module.route))
            .toList();

        if (visible.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox(height: 0));
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Text(
                  'Modules',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(
                height: 94,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: visible.length,
                  itemBuilder: (_, index) =>
                      _ModuleShortcut(module: visible[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _supportedRoutes = <String>{
  '/restaurants',
  '/transport',
  '/mechanics',
  '/expiry',
  '/group-buy',
  '/promotions',
  '/follows',
  '/services',
};

class _ModuleShortcut extends StatelessWidget {
  const _ModuleShortcut({required this.module});

  final MarketplaceModule module;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => GoRouter.of(context).push(module.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_iconFor(module.iconName)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    module.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String? name) {
  switch (name) {
    case 'storefront':
      return Icons.storefront_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'directions_bus':
      return Icons.directions_bus_outlined;
    case 'build':
      return Icons.build_outlined;
    case 'event_busy':
      return Icons.event_busy_outlined;
    case 'groups':
      return Icons.groups_outlined;
    case 'local_offer':
      return Icons.local_offer_outlined;
    case 'favorite':
      return Icons.favorite_outline;
    case 'handyman':
      return Icons.handyman_outlined;
    default:
      return Icons.apps_outlined;
  }
}
