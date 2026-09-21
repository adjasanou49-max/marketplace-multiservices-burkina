import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : ServiceRepository(client);
});

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  String? category;
  late Future<List<Map<String, dynamic>>> categoriesFuture;
  late Future<List<Map<String, dynamic>>> servicesFuture;

  @override
  void initState() {
    super.initState();
    final repository = ref.read(serviceRepositoryProvider);
    categoriesFuture =
        repository == null ? Future.value(const []) : repository.categories();
    servicesFuture = _loadServices(repository);
  }

  Future<List<Map<String, dynamic>>> _loadServices(
    ServiceRepository? repository,
  ) {
    return repository == null
        ? Future.value(const [])
        : repository.services(category: category);
  }

  void _selectCategory(String? value) {
    final repository = ref.read(serviceRepositoryProvider);
    setState(() {
      category = value;
      servicesFuture = _loadServices(repository);
    });
  }

  Future<void> _requestService(Map<String, dynamic> service) async {
    final repository = ref.read(serviceRepositoryProvider);
    if (repository == null) return;

    final controller = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Demander ${service['name']?.toString() ?? 'ce service'}',
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Décrivez votre besoin',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (description == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final requestId = await repository.createRequest(
        serviceId: service['id'].toString(),
        description: description,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Demande créée : $requestId')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            onPressed: () {
              final repository = ref.read(serviceRepositoryProvider);
              setState(() {
                categoriesFuture = repository == null
                    ? Future.value(const [])
                    : repository.categories();
                servicesFuture = _loadServices(repository);
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: categoriesFuture,
        builder: (context, categorySnapshot) {
          final categories = categorySnapshot.data ?? const [];
          return Column(
            children: [
              if (categories.isNotEmpty)
                SizedBox(
                  height: 56,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('Tous'),
                        selected: category == null,
                        onSelected: (_) => _selectCategory(null),
                      ),
                      const SizedBox(width: 8),
                      for (final item in categories) ...[
                        ChoiceChip(
                          label: Text(item['name']?.toString() ?? ''),
                          selected: category == item['slug'],
                          onSelected: (_) =>
                              _selectCategory(item['slug']?.toString()),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: servicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erreur : ${snapshot.error}'),
                      );
                    }

                    final items =
                        snapshot.data ?? const <Map<String, dynamic>>[];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('Aucun service disponible actuellement.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final service = items[index];
                        final rawProvider = service['service_providers'];
                        final provider = rawProvider is Map
                            ? Map<String, dynamic>.from(rawProvider)
                            : const <String, dynamic>{};
                        final price = service['price'];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.handyman_outlined),
                            ),
                            title: Text(
                              service['name']?.toString() ?? 'Service',
                            ),
                            subtitle: Text(
                              '${provider['display_name'] ?? 'Prestataire'}'
                              '${price == null ? '' : ' • $price XOF'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _requestService(service),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}