import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/courier_action_repository.dart';

class CourierPackagesPage extends ConsumerWidget {
 const CourierPackagesPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){
  final c=ref.watch(supabaseProvider);
  return Scaffold(appBar:AppBar(title:const Text('Mes colis')),body:FutureBuilder(
   future:c==null?null:CourierActionRepository(c).packages(),
   builder:(context,s){
    if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));
    final rows=(s.data as List<Map<String,dynamic>>?)??const [];
    return ListView.builder(itemCount:rows.length,itemBuilder:(_,i){
     final x=rows[i]; final p=x['order_packages'] is Map?Map<String,dynamic>.from(x['order_packages']):<String,dynamic>{};
     return Card(child:ListTile(title:Text('Colis #${(x['package_id']??'').toString().substring(0,8)}'),subtitle:Text('Affectation: ${x['status']??'—'} • Colis: ${p['status']??'—'}'),trailing:const Icon(Icons.local_shipping_outlined)));
    });
   }));
 }
}