import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/courier_repository.dart';

final courierRepositoryProvider=Provider<CourierRepository?>((ref){
 final c=ref.watch(supabaseProvider); return c==null?null:CourierRepository(c);
});
final courierAssignmentsProvider=FutureProvider((ref) async {
 final r=ref.watch(courierRepositoryProvider); return r==null?const []:r.assignments();
});

class CourierPage extends ConsumerWidget {
 const CourierPage({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){
  final a=ref.watch(courierAssignmentsProvider);
  return Scaffold(appBar:AppBar(title:const Text('Espace livreur')),body:a.when(
   loading:()=>const Center(child:CircularProgressIndicator()),
   error:(e,_)=>Center(child:Text('Erreur : $e')),
   data:(items)=>items.isEmpty?const Center(child:Text('Aucune livraison')):ListView.builder(
    padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(_,i){
     final x=items[i]; return Card(child:ListTile(
      leading:const Icon(Icons.local_shipping_outlined),
      title:Text('Colis ${x.packageId.substring(0,8)}'),
      subtitle:Text(x.status),trailing:Text(x.assignedAt.toLocal().toString().substring(0,16))));
    }))
  );
 }
}