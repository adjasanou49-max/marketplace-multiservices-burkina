import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/admin_product_repository.dart';

class AdminProductsPage extends ConsumerStatefulWidget {
  const AdminProductsPage({super.key});
  @override ConsumerState<AdminProductsPage> createState()=>_AdminProductsPageState();
}
class _AdminProductsPageState extends ConsumerState<AdminProductsPage> {
  late Future<List<Map<String,dynamic>>> future;
  @override void initState(){super.initState();future=_load();}
  Future<List<Map<String,dynamic>>> _load() async {
    final c=ref.read(supabaseProvider);
    if(c==null)return const [];
    return AdminProductRepository(c).pending();
  }
  @override Widget build(BuildContext context){
    final c=ref.watch(supabaseProvider);
    if(c==null)return const Scaffold(body:Center(child:Text('Supabase non configuré')));
    return Scaffold(appBar:AppBar(title:const Text('Produits')),body:FutureBuilder<List<Map<String,dynamic>>>(
      future:future,builder:(context,state){
        if(state.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        if(state.hasError)return Center(child:Text('Erreur : ${state.error}'));
        final rows=state.data??const [];
        return ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(context,i){
          final row=rows[i],status=row['status']?.toString()??'DRAFT',active=status=='ACTIVE';
          return ListTile(title:Text(row['name']?.toString()??'Produit'),subtitle:Text('${row['price']??0} • $status'),trailing:Switch(value:active,onChanged:(value)async{
            final messenger = ScaffoldMessenger.of(context);
            try {
              await AdminProductRepository(c).setStatus(
                row['id'].toString(),
                value ? 'ACTIVE' : 'INACTIVE',
                'Modification depuis administration',
              );
              if (mounted) {
                setState(() => future = _load());
              }
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
            }
          }));
        });
      },
    ));
  }
}
