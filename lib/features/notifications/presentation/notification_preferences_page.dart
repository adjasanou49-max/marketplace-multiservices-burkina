import 'package:marketplace_multiservices_burkina/core/errors/user_facing_error.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';

class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  bool orders = true;
  bool promotions = true;
  bool messages = true;
  bool delivery = true;
  bool services = true;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final row = await client.from('notification_preferences')
          .select('orders,promotions,messages,delivery,services')
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        orders = row?['orders'] as bool? ?? true;
        promotions = row?['promotions'] as bool? ?? true;
        messages = row?['messages'] as bool? ?? true;
        delivery = row?['delivery'] as bool? ?? true;
        services = row?['services'] as bool? ?? true;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;
    setState(() => saving = true);
    try {
      await client.from('notification_preferences').upsert({
        'user_id': user.id,
        'orders': orders,
        'promotions': promotions,
        'messages': messages,
        'delivery': delivery,
        'services': services,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Préférences enregistrées.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : ${userFacingError(error)}')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(supabaseProvider)?.auth.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Connectez-vous pour gérer vos notifications.')));
    }
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Préférences de notifications')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Tile(title: 'Commandes', value: orders, onChanged: (v) => setState(() => orders = v)),
          _Tile(title: 'Livraison', value: delivery, onChanged: (v) => setState(() => delivery = v)),
          _Tile(title: 'Messages', value: messages, onChanged: (v) => setState(() => messages = v)),
          _Tile(title: 'Services', value: services, onChanged: (v) => setState(() => services = v)),
          _Tile(title: 'Promotions', value: promotions, onChanged: (v) => setState(() => promotions = v)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.value, required this.onChanged});

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        child: SwitchListTile(
          title: Text(title),
          value: value,
          onChanged: onChanged,
        ),
      );
}
