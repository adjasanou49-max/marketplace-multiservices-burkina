import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/admin_dashboard_repository.dart';
class AdminDashboardPage extends ConsumerWidget {
 const AdminDashboardPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){final c=ref.watch(supabaseProvider);if(c==null)return const Scaffold(body:Center(child:Text('Supabase non configuré')));return Scaffold(appBar:AppBar(title:const Text('Administration')),body:FutureBuilder(future:AdminDashboardRepository(c).counts(),builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));final m=s.data??{};return GridView.count(crossAxisCount:2,padding:const EdgeInsets.all(16),crossAxisSpacing:12,mainAxisSpacing:12,children:m.entries.map((e)=>Card(child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(e.value.toString(),style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:6),Text(e.key)])))).toList());}));}
}