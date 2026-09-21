import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/seller_products_repository.dart';

final sellerProductsRepositoryProvider =
    Provider<SellerProductsRepository?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : SellerProductsRepository(client);
});

class SellerProductsPage extends ConsumerStatefulWidget {
  const SellerProductsPage({super.key});

  @override
  ConsumerState<SellerProductsPage> createState() =>
      _SellerProductsPageState();
}

class _SellerProductsPageState
    extends ConsumerState<SellerProductsPage> {
  late Future<List<Map<String, dynamic>>> _future;
  late Future<List<Map<String, dynamic>>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _future = _loadProducts();
    _shopsFuture = _loadShops();
  }

  Future<List<Map<String, dynamic>>> _loadProducts() {
    return ref.read(sellerProductsRepositoryProvider)?.products() ??
        Future.value(const []);
  }

  Future<List<Map<String, dynamic>>> _loadShops() {
    return ref.read(sellerProductsRepositoryProvider)?.shops() ??
        Future.value(const []);
  }

  Future<void> _create() async {
    final repo = ref.read(sellerProductsRepositoryProvider);
    if (repo == null) return;

    final shops = await _shopsFuture;
    final categories = await repo.categories();

    if (shops.isEmpty) {
      _show('Aucune boutique disponible pour ce compte.');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _NewProductDialog(
        shops: shops,
        categories: categories,
      ),
    );

    if (result == null) return;

    try {
      final id = await repo.createProduct(
        shopId: result['shop_id'].toString(),
        name: result['name'].toString(),
        price: num.tryParse(result['price'].toString()) ?? 0,
        categoryId: result['category_id']?.toString(),
        description: result['description']?.toString(),
        initialStock:
            int.tryParse(result['initial_stock'].toString()) ?? 0,
        isExpirable: result['is_expirable'] == true,
        expiryDate: result['expiry_date'] as DateTime?,
      );

      if (!mounted) return;
      setState(() => _future = _loadProducts());
      _show('Produit créé en brouillon : ' + id);
    } catch (error) {
      _show('Création impossible : ' + error.toString());
    }
  }

  Future<void> _editStock(Map<String, dynamic> product) async {
    final rawInventory = product['inventory'];
    final inventory = rawInventory is Map
        ? Map<String, dynamic>.from(rawInventory)
        : const <String, dynamic>{};

    final controller = TextEditingController(
      text: inventory['quantity']?.toString() ?? '0',
    );

    final value = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantité totale',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text.trim());
              if (quantity != null && quantity >= 0) {
                Navigator.pop(context, quantity);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null) return;

    final repo = ref.read(sellerProductsRepositoryProvider);
    if (repo == null) return;

    try {
      await repo.setStock(
        productId: product['id'].toString(),
        quantity: value,
      );

      if (!mounted) return;
      setState(() => _future = _loadProducts());
    } catch (error) {
      _show('Stock non modifié : ' + error.toString());
    }
  }

  void _show(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits vendeur'),
        actions: [
          IconButton(
            onPressed: _create,
            tooltip: 'Ajouter un produit',
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            onPressed: () => setState(() => _future = _loadProducts()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur produits : ' + snapshot.error.toString(),
              ),
            );
          }

          final products =
              snapshot.data ?? const <Map<String, dynamic>>[];

          if (products.isEmpty) {
            return const Center(
              child: Text('Aucun produit pour vos boutiques.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _loadProducts());
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final product = products[index];
                final inventory = product['inventory'] is Map
                    ? Map<String, dynamic>.from(product['inventory'] as Map)
                    : const <String, dynamic>{};
                final shop = product['shops'] is Map
                    ? Map<String, dynamic>.from(product['shops'] as Map)
                    : const <String, dynamic>{};

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    title: Text(
                      product['name']?.toString() ?? 'Produit',
                    ),
                    subtitle: Text(
                      (shop['name']?.toString() ?? 'Boutique') +
                          '\nStatut : ' +
                          (product['status']?.toString() ?? '-') +
                          '\nStock : ' +
                          (inventory['quantity']?.toString() ?? '0') +
                          ' • Réservé : ' +
                          (inventory['reserved_quantity']?.toString() ??
                              '0'),
                    ),
                    trailing: IconButton(
                      onPressed: () => _editStock(product),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modifier le stock',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewProductDialog extends StatefulWidget {
  const _NewProductDialog({
    required this.shops,
    required this.categories,
  });

  final List<Map<String, dynamic>> shops;
  final List<Map<String, dynamic>> categories;

  @override
  State<_NewProductDialog> createState() => _NewProductDialogState();
}

class _NewProductDialogState extends State<_NewProductDialog> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _description = TextEditingController();

  late String _shopId;
  String? _categoryId;
  bool _expirable = false;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _shopId = widget.shops.first['id'].toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un produit'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _shopId,
              decoration: const InputDecoration(labelText: 'Boutique'),
              items: widget.shops
                  .map(
                    (shop) => DropdownMenuItem<String>(
                      value: shop['id'].toString(),
                      child: Text(shop['name']?.toString() ?? 'Boutique'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _shopId = value);
              },
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix XOF'),
            ),
            TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock initial',
              ),
            ),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sans catégorie'),
                ),
                ...widget.categories.map(
                  (category) => DropdownMenuItem<String?>(
                    value: category['id'].toString(),
                    child: Text(
                      category['name']?.toString() ?? 'Catégorie',
                    ),
                  ),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _categoryId = value),
            ),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Produit avec date d’expiration'),
              value: _expirable,
              onChanged: (value) =>
                  setState(() => _expirable = value),
            ),
            if (_expirable)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _expiryDate == null
                      ? 'Date d’expiration'
                      : _expiryDate!
                          .toIso8601String()
                          .split('T')
                          .first,
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickExpiry,
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
          onPressed: () {
            final name = _name.text.trim();
            final price = num.tryParse(_price.text.trim());
            final stock = int.tryParse(_stock.text.trim());

            if (name.length < 2 ||
                price == null ||
                price < 0 ||
                stock == null ||
                stock < 0 ||
                (_expirable && _expiryDate == null)) {
              return;
            }

            Navigator.pop(
              context,
              {
                'shop_id': _shopId,
                'name': name,
                'price': price,
                'initial_stock': stock,
                'category_id': _categoryId,
                'description': _description.text.trim(),
                'is_expirable': _expirable,
                'expiry_date': _expiryDate,
              },
            );
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
