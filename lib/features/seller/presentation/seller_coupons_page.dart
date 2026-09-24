import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class SellerCouponsPage extends ConsumerStatefulWidget {
  const SellerCouponsPage({super.key});

  @override
  ConsumerState<SellerCouponsPage> createState() => _SellerCouponsPageState();
}

class _SellerCouponsPageState extends ConsumerState<SellerCouponsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
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
    final rows = await client
        .from('coupons')
        .select(
          'id,code,discount_type,discount_value,min_order_amount,max_uses,used_count,starts_at,ends_at,active',
        )
        .eq('seller_id', sellerId)
        .order('ends_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> _create() async {
    final form = await showDialog<_CouponForm>(
      context: context,
      builder: (_) => const _CouponDialog(),
    );
    if (form == null) return;

    final client = ref.read(supabaseProvider);
    if (client == null) return;

    try {
      final id = await client.rpc(
        'create_seller_coupon',
        params: {
          'p_code': form.code,
          'p_discount_type': form.type,
          'p_discount_value': form.value,
          'p_min_order_amount': form.minOrderAmount,
          'p_max_uses': form.maxUses,
          'p_starts_at': form.startsAt.toUtc().toIso8601String(),
          'p_ends_at': form.endsAt.toUtc().toIso8601String(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon créé : $id')),
      );
      setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon refusé : $error')),
      );
    }
  }

  Future<void> _toggle(Map<String, dynamic> coupon, bool active) async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;

    try {
      await client.rpc(
        'set_seller_coupon_active',
        params: {'p_coupon_id': coupon['id'], 'p_active': active},
      );
      if (mounted) setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modification refusée : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons'),
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
        label: const Text('Nouveau coupon'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final coupons = snapshot.data ?? const <Map<String, dynamic>>[];
          if (coupons.isEmpty) {
            return const Center(
              child: Text('Aucun coupon pour votre boutique.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final coupon = coupons[index];
              final value = coupon['discount_value']?.toString() ?? '0';
              final type = coupon['discount_type']?.toString() ?? 'FIXED';
              final used = coupon['used_count']?.toString() ?? '0';
              final max = coupon['max_uses']?.toString() ?? '∞';

              return Card(
                child: SwitchListTile(
                  title: Text(coupon['code']?.toString() ?? 'COUPON'),
                  subtitle: Text(
                    '${type} $value • utilisations $used/$max\nExpire : ${coupon['ends_at']?.toString() ?? '-'}',
                  ),
                  value: coupon['active'] == true,
                  onChanged: (value) => _toggle(coupon, value),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CouponForm {
  const _CouponForm({
    required this.code,
    required this.type,
    required this.value,
    required this.minOrderAmount,
    required this.maxUses,
    required this.startsAt,
    required this.endsAt,
  });

  final String code;
  final String type;
  final num value;
  final num minOrderAmount;
  final int? maxUses;
  final DateTime startsAt;
  final DateTime endsAt;
}

class _CouponDialog extends StatefulWidget {
  const _CouponDialog();

  @override
  State<_CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<_CouponDialog> {
  final code = TextEditingController();
  final value = TextEditingController();
  final min = TextEditingController(text: '0');
  final max = TextEditingController();
  String type = 'PERCENT';

  @override
  void dispose() {
    code.dispose();
    value.dispose();
    min.dispose();
    max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau coupon'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: 'PERCENT',
                  child: Text('Pourcentage'),
                ),
                DropdownMenuItem(
                  value: 'FIXED',
                  child: Text('Montant fixe'),
                ),
              ],
              onChanged: (next) {
                if (next != null) setState(() => type = next);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valeur de réduction',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: min,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Commande minimale (XOF)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre maximal d’utilisations',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            final parsedValue = num.tryParse(value.text.trim());
            final parsedMin = num.tryParse(min.text.trim());
            final parsedMax = int.tryParse(max.text.trim());

            if (code.text.trim().length < 3 ||
                parsedValue == null ||
                parsedMin == null ||
                (max.text.trim().isNotEmpty && parsedMax == null)) {
              return;
            }

            final ends = await showDatePicker(
              context: context,
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              initialDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (ends == null) return;
            if (!mounted) return;

            Navigator.pop(
              context,
              _CouponForm(
                code: code.text.trim(),
                type: type,
                value: parsedValue,
                minOrderAmount: parsedMin,
                maxUses: parsedMax,
                startsAt: DateTime.now(),
                endsAt: DateTime(ends.year, ends.month, ends.day, 23, 59, 59),
              ),
            );
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
