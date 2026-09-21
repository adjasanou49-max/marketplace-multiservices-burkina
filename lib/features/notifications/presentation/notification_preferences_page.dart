import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/notifications/push_notification_service.dart';

class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  bool _orders = true;
  bool _promotions = true;
  bool _messages = true;
  bool _delivery = true;
  bool _services = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final row = await client
          .from('notification_preferences')
          .select('orders,promotions,messages,delivery,services')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _orders = row?['orders'] as bool? ?? true;
        _promotions = row?['promotions'] as bool? ?? true;
        _messages = row?['messages'] as bool? ?? true;
        _delivery = row?['delivery'] as bool? ?? true;
        _services = row?['services'] as bool? ?? true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final client = ref.read(supabaseProvider);
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    setState(() => _saving = true);

    try {
      await client.from('notification_preferences').upsert(
        {
          'user_id': user.id,
          'orders': _orders,
          'promotions': _promotions,
          'messages': _messages,
          'delivery': _delivery,
          'services': _services,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Préférences enregistrées.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : ' + error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(supabaseProvider)?.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Connectez-vous pour gérer vos notifications.'),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Préférences de notifications')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _PreferenceTile(
            title: 'Commandes',
            subtitle: 'Création, paiement, préparation et statut des commandes',
            value: _orders,
            onChanged: (value) => setState(() => _orders = value),
          ),
          _PreferenceTile(
            title: 'Livraison',
            subtitle: 'Départ, suivi du livreur et livraison',
            value: _delivery,
            onChanged: (value) => setState(() => _delivery = value),
          ),
          _PreferenceTile(
            title: 'Messages',
            subtitle: 'Nouveaux messages et conversations',
            value: _messages,
            onChanged: (value) => setState(() => _messages = value),
          ),
          _PreferenceTile(
            title: 'Services',
            subtitle: 'Demandes de services et interventions',
            value: _services,
            onChanged: (value) => setState(() => _services = value),
          ),
          _PreferenceTile(
            title: 'Promotions',
            subtitle: 'Offres, coupons et nouveautés',
            value: _promotions,
            onChanged: (value) => setState(() => _promotions = value),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => PushNotificationService.instance
                .openSystemNotificationSettings(),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Réglages des notifications du téléphone'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
