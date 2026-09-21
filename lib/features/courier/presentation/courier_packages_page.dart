import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/courier_action_repository.dart';

class CourierPackagesPage extends ConsumerStatefulWidget {
  const CourierPackagesPage({super.key});

  @override
  ConsumerState<CourierPackagesPage> createState() =>
      _CourierPackagesPageState();
}

class _CourierPackagesPageState extends ConsumerState<CourierPackagesPage> {
  bool loading = false;

  Future<void> action(
    Future<void> Function() fn, {
    required ScaffoldMessengerState messenger,
  }) async {
    if (mounted) {
      setState(() => loading = true);
    }
    try {
      await fn();
      messenger.showSnackBar(
        const SnackBar(content: Text('Opération effectuée')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void onMenuSelected(
    BuildContext context,
    Map<String, dynamic> row,
    String packageId,
    String value,
  ) {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final repository = CourierActionRepository(client);

    switch (value) {
      case 'accept':
        action(
          () => repository.accept(row['id'] as String),
          messenger: messenger,
        );
        break;
      case 'pickup':
        _codeAction(
          context,
          'Code de récupération',
          (code) => action(
            () => repository.pickup(packageId, code),
            messenger: messenger,
          ),
        );
        break;
      case 'start':
        action(
          () => repository.startDelivery(packageId),
          messenger: messenger,
        );
        break;
      case 'deliver':
        _codeAction(
          context,
          'Code de livraison',
          (code) => action(
            () => repository.deliver(packageId, code),
            messenger: messenger,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes colis')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: client == null ? null : CourierActionRepository(client).packages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, index) {
              final row = rows[index];
              final packageMap = row['order_packages'] is Map
                  ? Map<String, dynamic>.from(row['order_packages'])
                  : <String, dynamic>{};
              final packageId = row['package_id']?.toString() ?? '';
              final shortPackageId = packageId.length > 8
                  ? packageId.substring(0, 8)
                  : packageId;
              final status = row['status']?.toString() ?? '';

              return Card(
                child: ListTile(
                  title: Text('Colis #$shortPackageId'),
                  subtitle: Text(
                    'Affectation: $status • Colis: ${packageMap['status'] ?? '—'}',
                  ),
                  trailing: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : client == null
                          ? null
                          : PopupMenuButton<String>(
                              onSelected: (value) => onMenuSelected(
                                context,
                                row,
                                packageId,
                                value,
                              ),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'accept',
                                  child: Text('Accepter'),
                                ),
                                PopupMenuItem(
                                  value: 'pickup',
                                  child: Text('Confirmer récupération'),
                                ),
                                PopupMenuItem(
                                  value: 'start',
                                  child: Text('Démarrer livraison'),
                                ),
                                PopupMenuItem(
                                  value: 'deliver',
                                  child: Text('Confirmer livraison'),
                                ),
                              ],
                            ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _codeAction(
  BuildContext context,
  String title,
  Future<void> Function(String) submit,
) async {
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 8,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Code sécurisé',
          hintText: 'Saisir le code fourni',
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
          child: const Text('Valider'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (code != null && code.isNotEmpty) {
    await submit(code);
  }
}
