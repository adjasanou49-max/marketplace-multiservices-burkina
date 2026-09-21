import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/admin_product_repository.dart';
class AdminProductsPage extends ConsumerWidget {
 const AdminProductsPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){
  final c=ref.watch(supabaseProvider);if(c==null)return const Scaffold(body:Center(child:Text('Supabase non configuré')));
  final repo=AdminProductRepository(c);
  return Scaffold(appBar:AppBar(title:const Text('Produits')),body:FutureBuilder(
   future:repo.pending(),builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));final rows=(s.data as List<Map<String,dynamic>>?)??const [];
    return ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(context,i){final x=rows[i];final status=x['status']?.toString()??'DRAFT';final active=status=='ACTIVE';return ListTile(title:Text(x['name']?.toString()??'Produit'),subtitle:Text('${x['price']??0} • $status'),trailing:Switch(value:active,onChanged:(v)async{await repo.setStatus(x['id'].toString(),v?'ACTIVE':'INACTIVE','Modification depuis administration');});});}));
 }
}