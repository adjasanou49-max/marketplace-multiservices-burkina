import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_stock_repository.dart';

final sellerStockRepositoryProvider=Provider<SellerStockRepository?>((ref){
 final c=ref.watch(supabaseProvider); return c==null?null:SellerStockRepository(c);
});

class SellerStockPage extends ConsumerWidget {
 const SellerStockPage({super.key, this.shopId});
 final String? shopId;
 @override Widget build(BuildContext context,WidgetRef ref){
  final repo=ref.watch(sellerStockRepositoryProvider);
  return Scaffold(appBar:AppBar(title:const Text('Stock')),body:FutureBuilder(
   future:repo?.stock(shopId: shopId),
   builder:(context,s){
    if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));
    final items=s.data ?? const <Map<String,dynamic>>[];
    return ListView.builder(padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(_,i){
     final x=items[i]; final p=x['products'] is Map?Map<String,dynamic>.from(x['products']):<String,dynamic>{};
     final q=x['quantity']??0, r=x['reserved_quantity']??0;
     return Card(child:ListTile(title:Text(p['name'] as String? ?? 'Produit'),subtitle:Text('Disponible: $q • Réservé: $r'),trailing:Text('Net: ${q-r}')));
    });
   }));
 }
}