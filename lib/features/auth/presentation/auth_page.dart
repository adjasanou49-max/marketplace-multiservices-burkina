import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final displayNameController = TextEditingController();

  bool register = false;
  bool loading = false;

  AuthRepository get repository => AuthRepository(Supabase.instance.client);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final displayName = displayNameController.text.trim();

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email requis et mot de passe de 6 caractères minimum.'),
        ),
      );
      return;
    }

    setState(() => loading = true);
    try {
      if (register) {
        await repository.signUp(
          email: email,
          password: password,
          displayName: displayName,
        );
      } else {
        await repository.signIn(email: email, password: password);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            register
                ? 'Compte créé. Vérifiez votre email si la confirmation est activée.'
                : 'Connexion réussie.',
          ),
        ),
      );
      if (!register) Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez votre email.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await repository.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(register ? 'Créer un compte' : 'Connexion'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Marketplace Multiservices Burkina',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (register)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: displayNameController,
                  enabled: !loading,
                  decoration: const InputDecoration(
                    labelText: 'Nom affiché',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading ? null : submit,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(register ? 'Créer mon compte' : 'Se connecter'),
            ),
            if (!register)
              TextButton(
                onPressed: loading ? null : forgotPassword,
                child: const Text('Mot de passe oublié ?'),
              ),
            TextButton(
              onPressed: loading
                  ? null
                  : () => setState(() => register = !register),
              child: Text(
                register
                    ? 'J’ai déjà un compte'
                    : 'Créer un nouveau compte',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
