import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/courier_action_repository.dart';

class CourierPackagesPage extends ConsumerStatefulWidget {
 const CourierPackagesPage({super.key});
 @override ConsumerState<CourierPackagesPage> createState()=>_CourierPackagesPageState();
}
class _CourierPackagesPageState extends ConsumerState<CourierPackagesPage>{
 bool loading=false;
 Future<void> action(Future<void> Function() fn) async {setState(()=>loading=true);try{await fn();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Opération effectuée')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Erreur : $e')));}finally{if(mounted)setState(()=>loading=false);}}
 @override Widget build(BuildContext context){final c=ref.watch(supabaseProvider);return Scaffold(appBar:AppBar(title:const Text('Mes colis')),body:FutureBuilder(future:c==null?null:CourierActionRepository(c).packages(),builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erreur : ${s.error}'));final rows=(s.data as List<Map<String,dynamic>>?)??const [];return ListView.builder(itemCount:rows.length,itemBuilder:(_,i){final x=rows[i];final p=x['order_packages'] is Map?Map<String,dynamic>.from(x['order_packages']):<String,dynamic>{};final packageId=x['package_id'] as String;final status=x['status']?.toString()??'';return Card(child:ListTile(title:Text('Colis #${packageId.substring(0,8)}'),subtitle:Text('Affectation: $status • Colis: ${p['status']??'—'}'),trailing:loading?const SizedBox(width:24,height:24,child:CircularProgressIndicator()):PopupMenuButton<String>(onSelected:(v)async{final repo=CourierActionRepository(c!);if(v=='accept')await action(()=>repo.accept(x['id'] as String));if(v=='pickup')await _codeAction(context,'Code de récupération', (code)=>action(()=>repo.pickup(packageId,code)));if(v=='start')await action(()=>repo.startDelivery(packageId));if(v=='deliver')await _codeAction(context,'Code de livraison', (code)=>action(()=>repo.deliver(packageId,code)));},itemBuilder:(_)=>const[PopupMenuItem(value:'accept',child:Text('Accepter')),PopupMenuItem(value:'pickup',child:Text('Confirmer récupération')),PopupMenuItem(value:'start',child:Text('Démarrer livraison')),PopupMenuItem(value:'deliver',child:Text('Confirmer livraison'))])));});}));}
}

Future<void> _codeAction(BuildContext context,String title,Future<void> Function(String) submit) async {
 final controller=TextEditingController();
 final code=await showDialog<String>(context:context,builder:(dialogContext)=>AlertDialog(
  title:Text(title),content:TextField(controller:controller,keyboardType:TextInputType.number,maxLength:8,autofocus:true,decoration:const InputDecoration(labelText:'Code sécurisé',hintText:'Saisir le code fourni')),
  actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(dialogContext,controller.text.trim()),child:const Text('Valider'))],));
 controller.dispose(); if(code!=null&&code.isNotEmpty) await submit(code);
}
