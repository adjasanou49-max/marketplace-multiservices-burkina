import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final client = ref.read(supabaseProvider);
    if (client == null) {
      _show('Configurez SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY.');
      return;
    }

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.length < 6) {
      _show(
        'Saisissez un email valide et un mot de passe d’au moins 6 caractères.',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_signUp) {
        await client.auth.signUp(
          email: email,
          password: password,
        );
        _show(
          'Compte créé. Vérifiez votre email si la confirmation est activée.',
        );
      } else {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (mounted) context.pop();
      }
    } catch (error) {
      _show('Échec de l’authentification : $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_signUp ? 'Créer un compte' : 'Connexion'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(
              _loading
                  ? 'Chargement…'
                  : (_signUp ? 'Créer le compte' : 'Se connecter'),
            ),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() => _signUp = !_signUp),
            child: Text(
              _signUp
                  ? 'J’ai déjà un compte'
                  : 'Créer un nouveau compte',
            ),
          ),
        ],
      ),
    );
  }
}
