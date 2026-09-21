import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_ledger_repository.dart';

class SellerFinancePage extends ConsumerWidget {
 const SellerFinancePage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){
  final c=ref.watch(supabaseProvider);
  return Scaffold(appBar:AppBar(title:const Text('Finances vendeur')),body:FutureBuilder(
   future:c==null?null:SellerLedgerRepository(c).mine(),
   builder:(context,s){
    if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));
    final rows=(s.data as List<Map<String,dynamic>>?)??const [];
    return ListView.separated(padding:const EdgeInsets.all(16),itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(_,i){
     final x=rows[i]; return ListTile(title:Text(x['entry_type'] as String???'Opération'),trailing:Text('${x['amount']??0} ${x['currency']??'XOF'}'),subtitle:Text(x['created_at'].toString()));
    });
   }));
 }
}