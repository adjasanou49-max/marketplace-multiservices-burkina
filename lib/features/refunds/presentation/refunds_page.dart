import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/refund_repository.dart';
class RefundsPage extends ConsumerWidget {
 const RefundsPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){final c=ref.watch(supabaseProvider);if(c==null)return const Scaffold(body:Center(child:Text('Supabase non configuré')));
  return Scaffold(appBar:AppBar(title:const Text('Remboursements')),body:FutureBuilder(future:RefundRepository(c).mine(),builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));final rows=(s.data as List<Map<String,dynamic>>?)??const [];if(rows.isEmpty)return const Center(child:Text('Aucun remboursement'));return ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i){final x=rows[i];return ListTile(leading:const Icon(Icons.currency_exchange),title:Text('${x['amount']??0} ${x['currency']??'XOF'}'),subtitle:Text('${x['reason']??'Motif non renseigné'} • ${x['created_at']??''}'),trailing:Text(x['status']?.toString()??'PENDING'));});}));
 }
}