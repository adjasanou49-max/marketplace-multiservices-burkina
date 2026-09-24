import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class SellerPromotionsPage extends ConsumerStatefulWidget {
  const SellerPromotionsPage({super.key});

  @override
  ConsumerState<SellerPromotionsPage> createState() =>
      _SellerPromotionsPageState();
}

class _SellerPromotionsPageState
    extends ConsumerState<SellerPromotionsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(String, List<Map<String, dynamic>>)> _loadBase() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw StateError('Authentification requise.');
    }

    final sellers = await client
        .from('sellers')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    if ((sellers as List).isEmpty) {
      throw StateError('Vendeur introuvable.');
    }

    final sellerId = (sellers.first as Map)['id'].toString();
    final shops = await client
        .from('shops')
        .select('id,name')
        .eq('seller_id', sellerId)
        .order('created_at')
        .limit(10);

    if ((shops as List).isEmpty) {
      throw StateError('Créez une boutique avant une promotion.');
    }

    final shopId = (shops.first as Map)['id'].toString();
    final rows = await client
        .from('promotions')
        .select(
          'id,shop_id,name,promotion_type,value,starts_at,ends_at,active',
        )
        .eq('seller_id', sellerId)
        .order('ends_at', ascending: false)
        .limit(100);

    return (
      shopId,
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final result = await _loadBase();
    return result.$2;
  }

  Future<void> _create() async {
    String? shopId;
    try {
      shopId = (await _loadBase()).$1;
    } catch (error) {
      _show('Création impossible : $error');
      return;
    }

    final form = await showDialog<_PromotionForm>(
      context: context,
      builder: (_) => const _PromotionDialog(),
    );
    if (form == null) return;
    if (!context.mounted) return;

    final client = ref.read(supabaseProvider);
    if (client == null) return;

    try {
      final id = await client.rpc(
        'create_seller_promotion',
        params: {
          'p_shop_id': shopId,
          'p_name': form.name,
          'p_promotion_type': form.type,
          'p_value': form.value,
          'p_starts_at': form.startsAt.toUtc().toIso8601String(),
          'p_ends_at': form.endsAt.toUtc().toIso8601String(),
        },
      );
      if (!mounted) return;
      _show('Promotion créée : $id');
      setState(() => _future = _load());
    } catch (error) {
      _show('Promotion refusée : $error');
    }
  }

  Future<void> _toggle(Map<String, dynamic> promotion, bool active) async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    try {
      await client.rpc(
        'set_seller_promotion_active',
        params: {
          'p_promotion_id': promotion['id'],
          'p_active': active,
        },
      );
      if (mounted) setState(() => _future = _load());
    } catch (error) {
      _show('Modification refusée : $error');
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions vendeur'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle promotion'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Erreur : ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final promotions =
              snapshot.data ?? const <Map<String, dynamic>>[];
          if (promotions.isEmpty) {
            return const Center(
              child: Text('Aucune promotion créée pour votre boutique.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: promotions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final p = promotions[index];
              return Card(
                child: SwitchListTile(
                  value: p['active'] == true,
                  onChanged: (value) => _toggle(p, value),
                  title: Text(p['name']?.toString() ?? 'Promotion'),
                  subtitle: Text(
                    '${p['promotion_type']?.toString() ?? '-'} • ${p['value']?.toString() ?? '0'}\nDu ${p['starts_at']?.toString() ?? '-'} au ${p['ends_at']?.toString() ?? '-'}',
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

class _PromotionForm {
  const _PromotionForm({
    required this.name,
    required this.type,
    required this.value,
    required this.startsAt,
    required this.endsAt,
  });

  final String name;
  final String type;
  final num value;
  final DateTime startsAt;
  final DateTime endsAt;
}

class _PromotionDialog extends StatefulWidget {
  const _PromotionDialog();

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  final name = TextEditingController();
  final value = TextEditingController();
  String type = 'PERCENT';

  @override
  void dispose() {
    name.dispose();
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle promotion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nom de la promotion'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'PERCENT', child: Text('Pourcentage')),
              DropdownMenuItem(value: 'FIXED', child: Text('Montant fixe')),
              DropdownMenuItem(value: 'FLASH', child: Text('Flash')),
              DropdownMenuItem(value: 'BUNDLE', child: Text('Pack / Bundle')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => type = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valeur'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            final parsed = num.tryParse(value.text.trim());
            final title = name.text.trim();
            if (title.length < 2 || parsed == null) return;

            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              initialDateRange: DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now().add(const Duration(days: 7)),
              ),
            );
            if (range == null) return;
            if (!context.mounted) return;

            Navigator.pop(
              context,
              _PromotionForm(
                name: title,
                type: type,
                value: parsed,
                startsAt: DateTime(
                  range.start.year,
                  range.start.month,
                  range.start.day,
                ),
                endsAt: DateTime(
                  range.end.year,
                  range.end.month,
                  range.end.day,
                  23,
                  59,
                  59,
                ),
              ),
            );
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
