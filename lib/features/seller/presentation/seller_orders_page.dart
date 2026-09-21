import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_order_repository.dart';

class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});
  @override Widget build(BuildContext context,WidgetRef ref){
    final c=ref.watch(supabaseProvider);
    return Scaffold(appBar:AppBar(title:const Text('Commandes vendeur')),body:FutureBuilder(
      future:c==null?null:SellerOrderRepository(c).mine(),
      builder:(context,s){
        if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));
        final rows=(s.data as List<Map<String,dynamic>>?)??const [];
        return ListView.separated(padding:const EdgeInsets.all(12),itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(_,i){
          final x=rows[i]; return ListTile(
            title:Text('Commande #${(x['order_id']??'').toString().substring(0,8)}'),
            subtitle:Text('Statut: ${x['status']??'—'} • Sous-total: ${x['subtotal']??0} XOF'),
            trailing:const Icon(Icons.chevron_right),
          );
        });
      }));
  }
}