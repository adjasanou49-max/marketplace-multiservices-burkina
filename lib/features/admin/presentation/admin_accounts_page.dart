import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/admin_account_repository.dart';
class AdminAccountsPage extends ConsumerWidget {
 const AdminAccountsPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){final c=ref.watch(supabaseProvider);if(c==null)return const Scaffold(body:Center(child:Text('Supabase non configuré')));return Scaffold(appBar:AppBar(title:const Text('Comptes')),body:const Center(child:Text('Gestion des comptes prête pour les actions sécurisées.')));}
}