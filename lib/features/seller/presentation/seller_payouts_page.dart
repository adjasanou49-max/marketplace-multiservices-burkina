import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/seller_payout_repository.dart';
class SellerPayoutsPage extends ConsumerWidget {
 const SellerPayoutsPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){final c=ref.watch(supabaseProvider);return Scaffold(appBar:AppBar(title:const Text('Paiements vendeur')),body:FutureBuilder(future:c==null?null:SellerPayoutRepository(c).mine(),builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));final rows=(s.data as List<Map<String,dynamic>>?)??const [];return ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(_,i){final x=rows[i];return ListTile(title:Text('${x['amount']??0} ${x['currency']??'XOF'}'),subtitle:Text('${x['provider']??'—'} • ${x['requested_at']??''}'),trailing:Text(x['status']?.toString()??'PENDING'));});}));}
}