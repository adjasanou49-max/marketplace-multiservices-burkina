import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/commission_repository.dart';
class CommissionsPage extends ConsumerWidget {
 const CommissionsPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){final c=ref.watch(supabaseProvider);if(c==null)return const Scaffold(body:Center(child:Text('Supabase non configuré')));
  return Scaffold(appBar:AppBar(title:const Text('Commissions')),body:FutureBuilder(future:CommissionRepository(c).mine(),builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));final rows=(s.data as List<Map<String,dynamic>>?)??const [];if(rows.isEmpty)return const Center(child:Text('Aucune écriture'));return ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i){final x=rows[i];return ListTile(title:Text('${x['entry_type']??x['type']??'Écriture'}'),subtitle:Text('${x['created_at']??''}'),trailing:Text('${x['amount']??0}'));});}));
 }
}