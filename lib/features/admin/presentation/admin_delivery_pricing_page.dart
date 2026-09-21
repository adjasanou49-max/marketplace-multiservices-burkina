import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/admin_delivery_pricing_repository.dart';

class AdminDeliveryPricingPage extends ConsumerStatefulWidget {
  const AdminDeliveryPricingPage({super.key});

  @override
  ConsumerState<AdminDeliveryPricingPage> createState() =>
      _AdminDeliveryPricingPageState();
}

class _AdminDeliveryPricingPageState extends ConsumerState<AdminDeliveryPricingPage> {
  late Future<List<DeliveryPricingRule>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<DeliveryPricingRule>> _load() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return const [];
    return AdminDeliveryPricingRepository(client).all();
  }

  Future<void> _edit(DeliveryPricingRule rule) async {
    final nameController = TextEditingController(text: rule.name);
    final baseController =
        TextEditingController(text: rule.baseFee.toStringAsFixed(0));
    final kmController =
        TextEditingController(text: rule.perKmFee.toStringAsFixed(0));
    final stopController =
        TextEditingController(text: rule.perStopFee.toStringAsFixed(0));
    var active = rule.active;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(rule.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: baseController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Forfait de base (XOF)'),
                ),
                TextField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Par km (XOF)'),
                ),
                TextField(
                  controller: stopController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Par arrêt supplémentaire (XOF)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarif actif'),
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      nameController.dispose();
      baseController.dispose();
      kmController.dispose();
      stopController.dispose();
      return;
    }

    final client = ref.read(supabaseProvider);
    if (client == null) return;
    try {
      await AdminDeliveryPricingRepository(client).updateRule(
        id: rule.id,
        name: nameController.text,
        baseFee: num.tryParse(baseController.text) ?? 0,
        perKmFee: num.tryParse(kmController.text) ?? 0,
        perStopFee: num.tryParse(stopController.text) ?? 0,
        active: active,
      );
      if (!mounted) return;
      setState(() => future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      nameController.dispose();
      baseController.dispose();
      kmController.dispose();
      stopController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseProvider);
    if (client == null) {
      return const Scaffold(
        body: Center(child: Text('Supabase non configuré')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Tarification livraison')),
      body: FutureBuilder<List<DeliveryPricingRule>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final rules = snapshot.data ?? const <DeliveryPricingRule>[];
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final rule = rules[index];
              final max = rule.maxDistanceKm == null
                  ? '+'
                  : '-${rule.maxDistanceKm!.toStringAsFixed(0)}';
              return Card(
                child: ListTile(
                  title: Text(rule.name),
                  subtitle: Text(
                    '${rule.minDistanceKm.toStringAsFixed(0)} km $max km • '
                    'base ${rule.baseFee.toStringAsFixed(0)} XOF • '
                    '+${rule.perKmFee.toStringAsFixed(0)} XOF/km',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rule.active ? Icons.check_circle : Icons.pause_circle,
                      ),
                      IconButton(
                        tooltip: 'Modifier',
                        onPressed: () => _edit(rule),
                        icon: const Icon(Icons.edit_outlined),
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