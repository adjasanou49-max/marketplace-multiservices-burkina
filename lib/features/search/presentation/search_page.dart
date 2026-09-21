import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/search_controller.dart';
import '../../products/presentation/product_grid.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final controller = TextEditingController();
  String query = '';

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider(query));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Rechercher...', border: InputBorder.none),
          onSubmitted: (value) => setState(() => query = value.trim()),
        ),
        actions: [
          IconButton(onPressed: () => setState(() => query = controller.text.trim()), icon: const Icon(Icons.search)),
        ],
      ),
      body: query.isEmpty
          ? const Center(child: Text('Saisissez un produit à rechercher'))
          : results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (items) => ProductGrid(products: items),
            ),
    );
  }
}
