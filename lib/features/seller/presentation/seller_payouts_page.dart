import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_payout_repository.dart';
class SellerPayoutsPage extends ConsumerWidget {
 const SellerPayoutsPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){
  final c=ref.watch(supabaseProvider);
  return Scaffold(appBar:AppBar(title:const Text('Reversements')),
   body:c==null?const Center(child:Text('Supabase non configuré')):FutureBuilder(
    future:SellerPayoutRepository(c).mine(),
    builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));final rows=(s.data as List<Map<String,dynamic>>?)??const [];
     if(rows.isEmpty)return const Center(child:Text('Aucun reversement'));
     return RefreshIndicator(onRefresh:()=>SellerPayoutRepository(c).mine().then((_){ }),child:ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i){final x=rows[i];return ListTile(leading:const Icon(Icons.account_balance_wallet_outlined),title:Text('${x['amount']??0} ${x['currency']??'XOF'}'),subtitle:Text('${x['provider']??'—'} • ${x['requested_at']??''}'),trailing:Chip(label:Text(x['status']?.toString()??'PENDING')));});});
    }));
 }
}