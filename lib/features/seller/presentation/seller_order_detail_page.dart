import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_order_repository.dart';

class SellerOrderDetailPage extends ConsumerWidget {
 const SellerOrderDetailPage({super.key,required this.groupId}); final String groupId;
 @override Widget build(BuildContext context,WidgetRef ref){
  final c=ref.watch(supabaseProvider);
  return Scaffold(appBar:AppBar(title:const Text('Détail commande')),body:FutureBuilder(
   future:c==null?null:SellerOrderRepository(c).detail(groupId),
   builder:(context,s){
    if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));
    final d=s.data as Map<String,dynamic>?; if(d==null)return const SizedBox();
    final g=Map<String,dynamic>.from(d['group'] as Map); final items=(d['items'] as List).cast<Map<String,dynamic>>();
    return ListView(padding:const EdgeInsets.all(16),children:[
      Text('Statut: ${g['status']??'—'}',style:Theme.of(context).textTheme.titleLarge),
      Text('Sous-total: ${g['subtotal']??0} XOF'),
      const Divider(),
      ...items.map((x)=>ListTile(title:Text(x['product_name'] as String? ?? 'Produit'),subtitle:Text('Quantité: ${x['quantity']??0}'),trailing:Text('${x['total_price']??0} XOF')))
    ]);
   }));
 }
}