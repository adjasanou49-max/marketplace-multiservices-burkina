import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/review_repository.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({
    super.key,
    required this.productId,
    required this.shopId,
    required this.productName,
  });

  final String productId;
  final String shopId;
  final String productName;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  int rating = 5;
  final bodyController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    bodyController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final client = ref.read(supabaseProvider);
    if (client == null) return;
    setState(() => loading = true);
    try {
      final id = await ReviewRepository(client).create(
        productId: widget.productId,
        shopId: widget.shopId,
        rating: rating,
        body: bodyController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avis envoyé : $id')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur avis : $error')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donner un avis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.productName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          const Text('Votre note'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: loading ? null : () => setState(() => rating = star),
                  iconSize: 36,
                  icon: Icon(
                    star <= rating ? Icons.star : Icons.star_border,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: bodyController,
            maxLines: 6,
            enabled: !loading,
            decoration: const InputDecoration(
              labelText: 'Commentaire (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : submit,
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Envoyer mon avis'),
          ),
        ],
      ),
    );
  }
}